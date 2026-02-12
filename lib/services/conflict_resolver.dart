import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import 'logger_service.dart';

/// Estrategias para resolver conflictos de sincronizacion.
enum ConflictStrategy {
  /// La version del servidor siempre gana
  serverWins,

  /// La version local siempre gana
  clientWins,

  /// La version mas reciente gana (por defecto)
  lastWriteWins,

  /// Intenta combinar los cambios (para objetos complejos)
  merge,

  /// Solicita al usuario que elija
  askUser,
}

/// Resultado de una resolucion de conflicto.
class ConflictResolution<T> {
  /// El registro resuelto
  final T resolved;

  /// La estrategia utilizada
  final ConflictStrategy strategyUsed;

  /// Si hubo conflicto real
  final bool hadConflict;

  /// Descripcion de los cambios realizados
  final String? changesSummary;

  ConflictResolution({
    required this.resolved,
    required this.strategyUsed,
    this.hadConflict = true,
    this.changesSummary,
  });
}

/// Registro de un conflicto para debugging y auditoria.
class ConflictLog {
  final String recordType;
  final String recordId;
  final DateTime timestamp;
  final ConflictStrategy strategyUsed;
  final Map<String, dynamic>? localVersion;
  final Map<String, dynamic>? remoteVersion;
  final Map<String, dynamic>? resolvedVersion;

  ConflictLog({
    required this.recordType,
    required this.recordId,
    required this.timestamp,
    required this.strategyUsed,
    this.localVersion,
    this.remoteVersion,
    this.resolvedVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'recordType': recordType,
      'recordId': recordId,
      'timestamp': timestamp.toIso8601String(),
      'strategyUsed': strategyUsed.name,
      'localVersion': localVersion,
      'remoteVersion': remoteVersion,
      'resolvedVersion': resolvedVersion,
    };
  }
}

/// Servicio para resolver conflictos de sincronizacion entre local y nube.
///
/// Este servicio implementa varias estrategias para resolver conflictos
/// cuando hay diferencias entre la version local (Hive) y la remota (Firebase).
class ConflictResolver {
  final _logger = LoggerService();
  /// Estrategia por defecto a utilizar
  final ConflictStrategy defaultStrategy;

  /// Historial de conflictos para debugging
  final List<ConflictLog> _conflictHistory = [];

  /// Maximo de registros en historial
  static const int _maxHistorySize = 100;

  ConflictResolver({
    this.defaultStrategy = ConflictStrategy.lastWriteWins,
  });

  /// Obtiene el historial de conflictos
  List<ConflictLog> get conflictHistory => List.unmodifiable(_conflictHistory);

  /// Detecta si hay conflicto entre versiones local y remota.
  ///
  /// Un conflicto existe cuando ambas versiones han sido modificadas
  /// desde la ultima sincronizacion exitosa.
  bool hasConflict(DateTime? localUpdate, DateTime? remoteUpdate) {
    if (localUpdate == null || remoteUpdate == null) {
      return false;
    }

    // Tolerancia de 1 segundo para diferencias de reloj
    final difference = localUpdate.difference(remoteUpdate).abs();
    if (difference.inSeconds < 1) {
      return false;
    }

    // Hay conflicto si ambos han sido actualizados recientemente
    // y ninguno es claramente mas nuevo
    return true;
  }

  /// Resuelve conflicto entre versiones local y remota de una tarea.
  ConflictResolution<Task> resolveTaskConflict(
    Task local,
    Task remote, {
    ConflictStrategy? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    // Verificar si realmente hay conflicto
    if (!hasConflict(local.lastUpdatedAt, remote.lastUpdatedAt)) {
      // Si no hay conflicto, usar la version mas reciente
      final resolved = _getNewerTask(local, remote);
      return ConflictResolution(
        resolved: resolved,
        strategyUsed: ConflictStrategy.lastWriteWins,
        hadConflict: false,
      );
    }

    Task resolved;
    String? changesSummary;

    switch (effectiveStrategy) {
      case ConflictStrategy.serverWins:
        resolved = remote.copyWith(
          firestoreId: remote.firestoreId.isNotEmpty
              ? remote.firestoreId
              : local.firestoreId,
        );
        changesSummary = 'Se mantuvo la version del servidor';
        break;

      case ConflictStrategy.clientWins:
        resolved = local;
        changesSummary = 'Se mantuvo la version local';
        break;

      case ConflictStrategy.lastWriteWins:
        resolved = _getNewerTask(local, remote);
        changesSummary = resolved == local
            ? 'Se mantuvo la version local (mas reciente)'
            : 'Se mantuvo la version del servidor (mas reciente)';
        break;

      case ConflictStrategy.merge:
        resolved = _mergeTaskConflict(local, remote);
        changesSummary = 'Se combinaron los cambios de ambas versiones';
        break;

      case ConflictStrategy.askUser:
        // Por defecto usar lastWriteWins, la UI deberia manejar askUser
        resolved = _getNewerTask(local, remote);
        changesSummary = 'Requiere decision del usuario';
        break;
    }

    // Registrar el conflicto
    logConflict('task', local.firestoreId, local, remote, resolved);

    return ConflictResolution(
      resolved: resolved,
      strategyUsed: effectiveStrategy,
      hadConflict: true,
      changesSummary: changesSummary,
    );
  }

  /// Resuelve conflicto entre versiones local y remota de una nota.
  ConflictResolution<Note> resolveNoteConflict(
    Note local,
    Note remote, {
    ConflictStrategy? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    // Verificar si realmente hay conflicto
    if (!hasConflict(local.updatedAt, remote.updatedAt)) {
      final resolved = _getNewerNote(local, remote);
      return ConflictResolution(
        resolved: resolved,
        strategyUsed: ConflictStrategy.lastWriteWins,
        hadConflict: false,
      );
    }

    Note resolved;
    String? changesSummary;

    switch (effectiveStrategy) {
      case ConflictStrategy.serverWins:
        resolved = remote.copyWith(
          firestoreId: remote.firestoreId.isNotEmpty
              ? remote.firestoreId
              : local.firestoreId,
        );
        changesSummary = 'Se mantuvo la version del servidor';
        break;

      case ConflictStrategy.clientWins:
        resolved = local;
        changesSummary = 'Se mantuvo la version local';
        break;

      case ConflictStrategy.lastWriteWins:
        resolved = _getNewerNote(local, remote);
        changesSummary = resolved == local
            ? 'Se mantuvo la version local (mas reciente)'
            : 'Se mantuvo la version del servidor (mas reciente)';
        break;

      case ConflictStrategy.merge:
        resolved = _mergeNoteConflict(local, remote);
        changesSummary = 'Se combinaron los cambios de ambas versiones';
        break;

      case ConflictStrategy.askUser:
        resolved = _getNewerNote(local, remote);
        changesSummary = 'Requiere decision del usuario';
        break;
    }

    // Registrar el conflicto
    logConflict('note', local.firestoreId, local, remote, resolved);

    return ConflictResolution(
      resolved: resolved,
      strategyUsed: effectiveStrategy,
      hadConflict: true,
      changesSummary: changesSummary,
    );
  }

  /// Registra un conflicto en el historial para debugging.
  void logConflict(
    String type,
    String id,
    dynamic local,
    dynamic remote,
    dynamic resolved,
  ) {
    final log = ConflictLog(
      recordType: type,
      recordId: id,
      timestamp: DateTime.now(),
      strategyUsed: defaultStrategy,
      localVersion: _toJsonSafe(local),
      remoteVersion: _toJsonSafe(remote),
      resolvedVersion: _toJsonSafe(resolved),
    );

    _conflictHistory.add(log);

    // Mantener el historial dentro del limite
    while (_conflictHistory.length > _maxHistorySize) {
      _conflictHistory.removeAt(0);
    }

    if (kDebugMode) {
      _logger.debug('ConflictResolver', '[CONFLICT] $type: $id');
      _logger.debug('ConflictResolver', '  Estrategia: ${defaultStrategy.name}');
      _logger.debug('ConflictResolver', '  Local: ${local?.toString().substring(0, 50)}...');
      _logger.debug('ConflictResolver', '  Remote: ${remote?.toString().substring(0, 50)}...');
    }
  }

  /// Limpia el historial de conflictos.
  void clearHistory() {
    _conflictHistory.clear();
  }

  /// Exporta el historial como JSON.
  List<Map<String, dynamic>> exportHistory() {
    return _conflictHistory.map((log) => log.toJson()).toList();
  }

  // ==================== METODOS PRIVADOS ====================

  Task _getNewerTask(Task local, Task remote) {
    final localTime = local.lastUpdatedAt ?? local.createdAt;
    final remoteTime = remote.lastUpdatedAt ?? remote.createdAt;

    if (localTime.isAfter(remoteTime)) {
      return local;
    }
    return remote.copyWith(
      firestoreId:
          remote.firestoreId.isNotEmpty ? remote.firestoreId : local.firestoreId,
    );
  }

  Note _getNewerNote(Note local, Note remote) {
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    }
    return remote.copyWith(
      firestoreId:
          remote.firestoreId.isNotEmpty ? remote.firestoreId : local.firestoreId,
    );
  }

  /// Combina cambios de dos versiones de una tarea.
  ///
  /// Reglas de merge:
  /// - Titulo: usa el mas reciente
  /// - isCompleted: si alguno esta completado, mantener completado
  /// - Prioridad: usa la mas alta
  /// - Campos opcionales: preferir el valor no nulo
  Task _mergeTaskConflict(Task local, Task remote) {
    final localTime = local.lastUpdatedAt ?? local.createdAt;
    final remoteTime = remote.lastUpdatedAt ?? remote.createdAt;

    return Task(
      firestoreId:
          remote.firestoreId.isNotEmpty ? remote.firestoreId : local.firestoreId,
      // Titulo: usar el mas reciente
      title: localTime.isAfter(remoteTime) ? local.title : remote.title,
      type: local.type, // Tipo no deberia cambiar
      // Completado: si alguno lo marco como completado, mantener
      isCompleted: local.isCompleted || remote.isCompleted,
      createdAt: local.createdAt.isBefore(remote.createdAt)
          ? local.createdAt
          : remote.createdAt,
      dueDate: local.dueDate ?? remote.dueDate,
      category: localTime.isAfter(remoteTime) ? local.category : remote.category,
      // Prioridad: usar la mas alta (mas urgente)
      priority: local.priority > remote.priority ? local.priority : remote.priority,
      dueTimeMinutes: local.dueTimeMinutes ?? remote.dueTimeMinutes,
      motivation: local.motivation ?? remote.motivation,
      reward: local.reward ?? remote.reward,
      recurrenceDay: local.recurrenceDay ?? remote.recurrenceDay,
      // Deadline: usar la mas cercana si ambas existen
      deadline: _getMergedDeadline(local.deadline, remote.deadline),
      deleted: local.deleted || remote.deleted,
      deletedAt: local.deletedAt ?? remote.deletedAt,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Combina cambios de dos versiones de una nota.
  ///
  /// Reglas de merge:
  /// - Titulo: usa el mas reciente
  /// - Contenido: concatena si son diferentes
  /// - Tags: combina ambas listas
  /// - Pinned: si alguno esta pinned, mantener
  Note _mergeNoteConflict(Note local, Note remote) {
    // Combinar tags sin duplicados
    final mergedTags = {...local.tags, ...remote.tags}.toList();

    // Contenido: si son muy diferentes, incluir ambos
    String mergedContent;
    if (local.content == remote.content) {
      mergedContent = local.content;
    } else if (local.content.contains(remote.content)) {
      mergedContent = local.content;
    } else if (remote.content.contains(local.content)) {
      mergedContent = remote.content;
    } else {
      // Contenidos diferentes, concatenar con separador
      mergedContent = '${local.content}\n\n---\n[Contenido sincronizado]\n${remote.content}';
    }

    return Note(
      firestoreId:
          remote.firestoreId.isNotEmpty ? remote.firestoreId : local.firestoreId,
      title: local.updatedAt.isAfter(remote.updatedAt) ? local.title : remote.title,
      content: mergedContent,
      createdAt: local.createdAt.isBefore(remote.createdAt)
          ? local.createdAt
          : remote.createdAt,
      updatedAt: DateTime.now(),
      taskId: local.taskId ?? remote.taskId,
      color: local.updatedAt.isAfter(remote.updatedAt) ? local.color : remote.color,
      isPinned: local.isPinned || remote.isPinned,
      tags: mergedTags,
      deleted: local.deleted || remote.deleted,
      deletedAt: local.deletedAt ?? remote.deletedAt,
    );
  }

  DateTime? _getMergedDeadline(DateTime? local, DateTime? remote) {
    if (local == null) return remote;
    if (remote == null) return local;
    // Usar el deadline mas cercano (mas urgente)
    return local.isBefore(remote) ? local : remote;
  }

  Map<String, dynamic>? _toJsonSafe(dynamic obj) {
    try {
      if (obj is Task) return obj.toFirestore();
      if (obj is Note) return obj.toFirestore();
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Provider para ConflictResolver
final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return ConflictResolver();
});

/// Provider con estrategia configurable
final conflictResolverWithStrategyProvider =
    Provider.family<ConflictResolver, ConflictStrategy>((ref, strategy) {
  return ConflictResolver(defaultStrategy: strategy);
});
