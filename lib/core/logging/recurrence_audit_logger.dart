/// Logger de auditoria para operaciones de recurrencia en AuraList.
///
/// Este modulo proporciona un sistema de logging estructurado para rastrear
/// todas las operaciones relacionadas con reglas de recurrencia, incluyendo:
/// - Creacion, modificacion y eliminacion de reglas
/// - Generacion de ocurrencias
/// - Excepciones y fechas excluidas
/// - Eventos de sincronizacion
/// - Errores de validacion
///
/// El logger mantiene un buffer circular en memoria de los ultimos 1000 eventos
/// para debugging y analisis sin impactar el rendimiento.
///
/// Ejemplo de uso:
/// ```dart
/// final logger = RecurrenceAuditLogger.instance;
/// logger.logRuleCreated(rule);
/// logger.logOccurrenceGenerated(rule, DateTime.now());
///
/// // Exportar para debugging
/// final events = logger.getRecentEvents(50);
/// final json = logger.exportToJson();
/// ```
library;

import 'dart:convert';

import '../../models/recurrence_rule.dart';

// =============================================================================
// ENUMS
// =============================================================================

/// Tipos de eventos de recurrencia para logging.
///
/// Cada tipo representa una operacion o estado especifico en el ciclo de vida
/// de una regla de recurrencia.
enum RecurrenceEventType {
  /// Regla de recurrencia creada
  created,

  /// Regla de recurrencia modificada
  modified,

  /// Regla de recurrencia eliminada
  deleted,

  /// Nueva ocurrencia generada
  occurrenceGenerated,

  /// Ocurrencia completada por el usuario
  occurrenceCompleted,

  /// Ocurrencia omitida manualmente
  occurrenceSkipped,

  /// Fecha de excepcion agregada
  exceptionAdded,

  /// Fecha de excepcion removida
  exceptionRemoved,

  /// Error de validacion detectado
  validationError,

  /// Sincronizacion iniciada
  syncStarted,

  /// Sincronizacion completada exitosamente
  syncCompleted,

  /// Sincronizacion fallida
  syncFailed,
}

/// Extension para RecurrenceEventType con propiedades utiles.
extension RecurrenceEventTypeExtension on RecurrenceEventType {
  /// Nombre en espanol para mostrar al usuario.
  String get spanishName {
    switch (this) {
      case RecurrenceEventType.created:
        return 'Creada';
      case RecurrenceEventType.modified:
        return 'Modificada';
      case RecurrenceEventType.deleted:
        return 'Eliminada';
      case RecurrenceEventType.occurrenceGenerated:
        return 'Ocurrencia generada';
      case RecurrenceEventType.occurrenceCompleted:
        return 'Ocurrencia completada';
      case RecurrenceEventType.occurrenceSkipped:
        return 'Ocurrencia omitida';
      case RecurrenceEventType.exceptionAdded:
        return 'Excepcion agregada';
      case RecurrenceEventType.exceptionRemoved:
        return 'Excepcion removida';
      case RecurrenceEventType.validationError:
        return 'Error de validacion';
      case RecurrenceEventType.syncStarted:
        return 'Sincronizacion iniciada';
      case RecurrenceEventType.syncCompleted:
        return 'Sincronizacion completada';
      case RecurrenceEventType.syncFailed:
        return 'Sincronizacion fallida';
    }
  }

  /// Codigo corto para logs compactos.
  String get code {
    switch (this) {
      case RecurrenceEventType.created:
        return 'CRT';
      case RecurrenceEventType.modified:
        return 'MOD';
      case RecurrenceEventType.deleted:
        return 'DEL';
      case RecurrenceEventType.occurrenceGenerated:
        return 'GEN';
      case RecurrenceEventType.occurrenceCompleted:
        return 'CMP';
      case RecurrenceEventType.occurrenceSkipped:
        return 'SKP';
      case RecurrenceEventType.exceptionAdded:
        return 'EXA';
      case RecurrenceEventType.exceptionRemoved:
        return 'EXR';
      case RecurrenceEventType.validationError:
        return 'VER';
      case RecurrenceEventType.syncStarted:
        return 'SYS';
      case RecurrenceEventType.syncCompleted:
        return 'SYC';
      case RecurrenceEventType.syncFailed:
        return 'SYF';
    }
  }

  /// Indica si es un evento de error.
  bool get isError {
    return this == RecurrenceEventType.validationError ||
        this == RecurrenceEventType.syncFailed;
  }

  /// Indica si es un evento de sincronizacion.
  bool get isSyncEvent {
    return this == RecurrenceEventType.syncStarted ||
        this == RecurrenceEventType.syncCompleted ||
        this == RecurrenceEventType.syncFailed;
  }

  /// Indica si es un evento de modificacion de regla.
  bool get isRuleLifecycleEvent {
    return this == RecurrenceEventType.created ||
        this == RecurrenceEventType.modified ||
        this == RecurrenceEventType.deleted;
  }
}

/// Tipos de eventos de sincronizacion.
///
/// Representa los diferentes estados de una operacion de sincronizacion.
enum SyncEventType {
  /// Sincronizacion iniciada
  started,

  /// Sincronizacion completada exitosamente
  completed,

  /// Sincronizacion fallida
  failed,

  /// Reintentando sincronizacion
  retrying,
}

/// Extension para SyncEventType con propiedades utiles.
extension SyncEventTypeExtension on SyncEventType {
  /// Nombre en espanol.
  String get spanishName {
    switch (this) {
      case SyncEventType.started:
        return 'Iniciada';
      case SyncEventType.completed:
        return 'Completada';
      case SyncEventType.failed:
        return 'Fallida';
      case SyncEventType.retrying:
        return 'Reintentando';
    }
  }

  /// Convierte a RecurrenceEventType correspondiente.
  RecurrenceEventType toRecurrenceEventType() {
    switch (this) {
      case SyncEventType.started:
        return RecurrenceEventType.syncStarted;
      case SyncEventType.completed:
        return RecurrenceEventType.syncCompleted;
      case SyncEventType.failed:
      case SyncEventType.retrying:
        return RecurrenceEventType.syncFailed;
    }
  }
}

// =============================================================================
// RECURRENCE EVENT
// =============================================================================

/// Representa un evento de auditoria de recurrencia.
///
/// Contiene toda la informacion necesaria para rastrear y depurar
/// operaciones de recurrencia, incluyendo timestamp, tipo, ID de regla
/// y detalles adicionales.
class RecurrenceEvent {
  /// Timestamp de cuando ocurrio el evento.
  final DateTime timestamp;

  /// Tipo de evento.
  final RecurrenceEventType eventType;

  /// ID de la regla afectada (si aplica).
  final String? ruleId;

  /// Detalles adicionales del evento.
  final Map<String, dynamic> details;

  /// Crea un nuevo evento de recurrencia.
  RecurrenceEvent({
    DateTime? timestamp,
    required this.eventType,
    this.ruleId,
    Map<String, dynamic>? details,
  })  : timestamp = timestamp ?? DateTime.now(),
        details = details ?? {};

  /// Crea un evento desde JSON.
  factory RecurrenceEvent.fromJson(Map<String, dynamic> json) {
    return RecurrenceEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: RecurrenceEventType.values[json['eventType'] as int],
      ruleId: json['ruleId'] as String?,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
    );
  }

  /// Convierte el evento a JSON.
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.index,
      'eventTypeName': eventType.name,
      'ruleId': ruleId,
      'details': details,
    };
  }

  /// Crea una copia del evento con campos modificados.
  RecurrenceEvent copyWith({
    DateTime? timestamp,
    RecurrenceEventType? eventType,
    String? ruleId,
    bool clearRuleId = false,
    Map<String, dynamic>? details,
  }) {
    return RecurrenceEvent(
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      ruleId: clearRuleId ? null : (ruleId ?? this.ruleId),
      details: details ?? Map.from(this.details),
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}]');
    buffer.write(' [${eventType.code}]');
    if (ruleId != null) {
      buffer.write(' [ruleId: $ruleId]');
    }
    buffer.write(' ${eventType.spanishName}');
    if (details.isNotEmpty) {
      buffer.write(' | ');
      buffer.write(details.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecurrenceEvent) return false;

    return timestamp == other.timestamp &&
        eventType == other.eventType &&
        ruleId == other.ruleId;
  }

  @override
  int get hashCode => Object.hash(timestamp, eventType, ruleId);
}

// =============================================================================
// RECURRENCE AUDIT LOGGER
// =============================================================================

/// Logger de auditoria singleton para operaciones de recurrencia.
///
/// Mantiene un buffer circular en memoria de los ultimos eventos para
/// debugging y analisis. Es thread-safe mediante un lock simple.
///
/// Uso:
/// ```dart
/// final logger = RecurrenceAuditLogger.instance;
/// logger.logRuleCreated(rule);
/// ```
class RecurrenceAuditLogger {
  /// Instancia singleton del logger.
  static final RecurrenceAuditLogger instance = RecurrenceAuditLogger._();

  /// Capacidad maxima del buffer circular.
  static const int _maxBufferSize = 1000;

  /// Buffer circular de eventos.
  final List<RecurrenceEvent> _eventBuffer = [];

  /// Lock para operaciones thread-safe.
  bool _isLocked = false;

  /// Constructor privado para singleton.
  RecurrenceAuditLogger._();

  /// Constructor factory que retorna la instancia singleton.
  factory RecurrenceAuditLogger() => instance;

  // ===========================================================================
  // METODOS DE LOGGING PRINCIPALES
  // ===========================================================================

  /// Registra un evento de recurrencia.
  ///
  /// Este es el metodo base para logging. Los metodos especificos
  /// (logRuleCreated, logOccurrenceGenerated, etc.) son wrappers
  /// convenientes sobre este metodo.
  void log(RecurrenceEvent event) {
    _withLock(() {
      _eventBuffer.add(event);
      // Mantener el buffer dentro del limite
      if (_eventBuffer.length > _maxBufferSize) {
        _eventBuffer.removeAt(0);
      }
    });
  }

  /// Registra la creacion de una regla de recurrencia.
  ///
  /// [rule] La regla que fue creada.
  void logRuleCreated(RecurrenceRule rule) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.created,
      ruleId: _getRuleId(rule),
      details: {
        'frequency': rule.frequency.name,
        'interval': rule.interval,
        'startDate': rule.startDate.toIso8601String(),
        if (rule.endDate != null) 'endDate': rule.endDate!.toIso8601String(),
        if (rule.count != null) 'count': rule.count,
        if (rule.preset != null) 'preset': rule.preset,
        if (rule.byDays.isNotEmpty) 'byDays': rule.byDays.map((d) => d.name).toList(),
        if (rule.weekPosition != null) 'weekPosition': rule.weekPosition,
      },
    ));
  }

  /// Registra la modificacion de una regla de recurrencia.
  ///
  /// [oldRule] La regla antes de la modificacion.
  /// [newRule] La regla despues de la modificacion.
  void logRuleModified(RecurrenceRule oldRule, RecurrenceRule newRule) {
    final changes = _detectChanges(oldRule, newRule);
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.modified,
      ruleId: _getRuleId(newRule),
      details: {
        'changes': changes,
        'changeCount': changes.length,
      },
    ));
  }

  /// Registra la eliminacion de una regla de recurrencia.
  ///
  /// [ruleId] ID de la regla eliminada.
  void logRuleDeleted(String ruleId) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.deleted,
      ruleId: ruleId,
      details: {
        'deletedAt': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Registra la generacion de una ocurrencia.
  ///
  /// [rule] La regla que genero la ocurrencia.
  /// [date] La fecha de la ocurrencia generada.
  void logOccurrenceGenerated(RecurrenceRule rule, DateTime date) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.occurrenceGenerated,
      ruleId: _getRuleId(rule),
      details: {
        'occurrenceDate': date.toIso8601String(),
        'frequency': rule.frequency.name,
      },
    ));
  }

  /// Registra la completacion de una ocurrencia.
  ///
  /// [ruleId] ID de la regla.
  /// [date] Fecha de la ocurrencia completada.
  void logOccurrenceCompleted(String ruleId, DateTime date) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.occurrenceCompleted,
      ruleId: ruleId,
      details: {
        'completedDate': date.toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
      },
    ));
  }

  /// Registra que una ocurrencia fue omitida.
  ///
  /// [ruleId] ID de la regla.
  /// [date] Fecha de la ocurrencia omitida.
  /// [reason] Razon por la que fue omitida (opcional).
  void logOccurrenceSkipped(String ruleId, DateTime date, {String? reason}) {
    final detailsMap = <String, dynamic>{
      'skippedDate': date.toIso8601String(),
    };
    if (reason != null) {
      detailsMap['reason'] = reason;
    }
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.occurrenceSkipped,
      ruleId: ruleId,
      details: detailsMap,
    ));
  }

  /// Registra que se agrego una fecha de excepcion a una regla.
  ///
  /// [ruleId] ID de la regla.
  /// [date] Fecha de excepcion agregada.
  void logExceptionAdded(String ruleId, DateTime date) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.exceptionAdded,
      ruleId: ruleId,
      details: {
        'exceptionDate': date.toIso8601String(),
      },
    ));
  }

  /// Registra que se removio una fecha de excepcion de una regla.
  ///
  /// [ruleId] ID de la regla.
  /// [date] Fecha de excepcion removida.
  void logExceptionRemoved(String ruleId, DateTime date) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.exceptionRemoved,
      ruleId: ruleId,
      details: {
        'exceptionDate': date.toIso8601String(),
      },
    ));
  }

  /// Registra un error de validacion.
  ///
  /// [rule] La regla que fallo la validacion.
  /// [error] Descripcion del error.
  void logValidationError(RecurrenceRule rule, String error) {
    log(RecurrenceEvent(
      eventType: RecurrenceEventType.validationError,
      ruleId: _getRuleId(rule),
      details: {
        'error': error,
        'frequency': rule.frequency.name,
        'interval': rule.interval,
      },
    ));
  }

  /// Registra un evento de sincronizacion.
  ///
  /// [ruleId] ID de la regla siendo sincronizada.
  /// [type] Tipo de evento de sincronizacion.
  /// [details] Detalles adicionales (opcional).
  void logSyncEvent(
    String ruleId,
    SyncEventType type, {
    Map<String, dynamic>? details,
  }) {
    log(RecurrenceEvent(
      eventType: type.toRecurrenceEventType(),
      ruleId: ruleId,
      details: {
        'syncType': type.name,
        ...?details,
      },
    ));
  }

  // ===========================================================================
  // METODOS DE CONSULTA
  // ===========================================================================

  /// Obtiene los ultimos N eventos del buffer.
  ///
  /// [count] Numero de eventos a retornar (por defecto 50).
  /// Retorna los eventos mas recientes primero.
  List<RecurrenceEvent> getRecentEvents([int count = 50]) {
    return _withLock(() {
      final effectiveCount = count.clamp(0, _eventBuffer.length);
      if (effectiveCount == 0) return <RecurrenceEvent>[];

      return _eventBuffer
          .skip(_eventBuffer.length - effectiveCount)
          .toList()
          .reversed
          .toList();
    });
  }

  /// Filtra eventos por tipo.
  ///
  /// [eventType] Tipo de evento a filtrar.
  /// [count] Numero maximo de eventos a retornar.
  List<RecurrenceEvent> getEventsByType(
    RecurrenceEventType eventType, {
    int? count,
  }) {
    return _withLock(() {
      var filtered = _eventBuffer.where((e) => e.eventType == eventType);
      if (count != null) {
        filtered = filtered.take(count);
      }
      return filtered.toList().reversed.toList();
    });
  }

  /// Filtra eventos por ID de regla.
  ///
  /// [ruleId] ID de la regla.
  /// [count] Numero maximo de eventos a retornar.
  List<RecurrenceEvent> getEventsByRuleId(
    String ruleId, {
    int? count,
  }) {
    return _withLock(() {
      var filtered = _eventBuffer.where((e) => e.ruleId == ruleId);
      if (count != null) {
        filtered = filtered.take(count);
      }
      return filtered.toList().reversed.toList();
    });
  }

  /// Filtra eventos por rango de fechas.
  ///
  /// [startDate] Fecha de inicio del rango.
  /// [endDate] Fecha de fin del rango.
  List<RecurrenceEvent> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _withLock(() {
      return _eventBuffer
          .where((e) =>
              e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate))
          .toList()
          .reversed
          .toList();
    });
  }

  /// Filtra eventos por multiples criterios.
  ///
  /// [eventType] Tipo de evento (opcional).
  /// [ruleId] ID de regla (opcional).
  /// [startDate] Fecha de inicio (opcional).
  /// [endDate] Fecha de fin (opcional).
  /// [count] Numero maximo de eventos.
  List<RecurrenceEvent> filterEvents({
    RecurrenceEventType? eventType,
    String? ruleId,
    DateTime? startDate,
    DateTime? endDate,
    int? count,
  }) {
    return _withLock(() {
      Iterable<RecurrenceEvent> result = _eventBuffer;

      if (eventType != null) {
        result = result.where((e) => e.eventType == eventType);
      }

      if (ruleId != null) {
        result = result.where((e) => e.ruleId == ruleId);
      }

      if (startDate != null) {
        result = result.where((e) => e.timestamp.isAfter(startDate));
      }

      if (endDate != null) {
        result = result.where((e) => e.timestamp.isBefore(endDate));
      }

      var list = result.toList().reversed.toList();

      if (count != null && list.length > count) {
        list = list.take(count).toList();
      }

      return list;
    });
  }

  /// Obtiene solo eventos de error.
  List<RecurrenceEvent> getErrorEvents({int? count}) {
    return _withLock(() {
      var filtered = _eventBuffer.where((e) => e.eventType.isError);
      if (count != null) {
        filtered = filtered.take(count);
      }
      return filtered.toList().reversed.toList();
    });
  }

  /// Obtiene eventos de sincronizacion.
  List<RecurrenceEvent> getSyncEvents({int? count}) {
    return _withLock(() {
      var filtered = _eventBuffer.where((e) => e.eventType.isSyncEvent);
      if (count != null) {
        filtered = filtered.take(count);
      }
      return filtered.toList().reversed.toList();
    });
  }

  // ===========================================================================
  // METODOS DE EXPORTACION
  // ===========================================================================

  /// Exporta todos los eventos a formato JSON.
  ///
  /// Retorna un string JSON con todos los eventos del buffer,
  /// incluyendo metadatos sobre la exportacion.
  String exportToJson() {
    return _withLock(() {
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'eventCount': _eventBuffer.length,
        'maxBufferSize': _maxBufferSize,
        'events': _eventBuffer.map((e) => e.toJson()).toList(),
      };
      return const JsonEncoder.withIndent('  ').convert(exportData);
    });
  }

  /// Exporta eventos filtrados a formato JSON.
  ///
  /// [events] Lista de eventos a exportar.
  String exportEventsToJson(List<RecurrenceEvent> events) {
    final exportData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'eventCount': events.length,
      'events': events.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Importa eventos desde JSON.
  ///
  /// [jsonString] String JSON con los eventos a importar.
  /// [replaceExisting] Si es true, reemplaza el buffer existente.
  void importFromJson(String jsonString, {bool replaceExisting = false}) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final eventsList = data['events'] as List<dynamic>;
    final events = eventsList
        .map((e) => RecurrenceEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    _withLock(() {
      if (replaceExisting) {
        _eventBuffer.clear();
      }
      for (final event in events) {
        _eventBuffer.add(event);
        if (_eventBuffer.length > _maxBufferSize) {
          _eventBuffer.removeAt(0);
        }
      }
    });
  }

  // ===========================================================================
  // METODOS DE UTILIDAD
  // ===========================================================================

  /// Limpia todos los eventos del buffer.
  void clear() {
    _withLock(() {
      _eventBuffer.clear();
    });
  }

  /// Obtiene el numero actual de eventos en el buffer.
  int get eventCount => _eventBuffer.length;

  /// Verifica si el buffer esta vacio.
  bool get isEmpty => _eventBuffer.isEmpty;

  /// Verifica si el buffer esta lleno.
  bool get isFull => _eventBuffer.length >= _maxBufferSize;

  /// Obtiene estadisticas del buffer.
  Map<String, dynamic> getStatistics() {
    return _withLock(() {
      final stats = <RecurrenceEventType, int>{};
      for (final event in _eventBuffer) {
        stats[event.eventType] = (stats[event.eventType] ?? 0) + 1;
      }

      DateTime? oldest;
      DateTime? newest;
      if (_eventBuffer.isNotEmpty) {
        oldest = _eventBuffer.first.timestamp;
        newest = _eventBuffer.last.timestamp;
      }

      return {
        'totalEvents': _eventBuffer.length,
        'maxBufferSize': _maxBufferSize,
        'bufferUsage': (_eventBuffer.length / _maxBufferSize * 100).toStringAsFixed(1),
        'oldestEvent': oldest?.toIso8601String(),
        'newestEvent': newest?.toIso8601String(),
        'eventsByType': stats.map((k, v) => MapEntry(k.name, v)),
        'errorCount': stats[RecurrenceEventType.validationError] ?? 0,
        'syncFailures': stats[RecurrenceEventType.syncFailed] ?? 0,
      };
    });
  }

  // ===========================================================================
  // METODOS PRIVADOS
  // ===========================================================================

  /// Obtiene un ID unico para una regla.
  ///
  /// Usa el hashCode de la regla como ID si no tiene uno asignado.
  String _getRuleId(RecurrenceRule rule) {
    // Usar el key de Hive si esta disponible, sino generar uno basado en hashCode
    if (rule.key != null) {
      return rule.key.toString();
    }
    return 'rule_${rule.hashCode}';
  }

  /// Detecta cambios entre dos versiones de una regla.
  Map<String, dynamic> _detectChanges(RecurrenceRule oldRule, RecurrenceRule newRule) {
    final changes = <String, dynamic>{};

    if (oldRule.frequency != newRule.frequency) {
      changes['frequency'] = {
        'old': oldRule.frequency.name,
        'new': newRule.frequency.name,
      };
    }

    if (oldRule.interval != newRule.interval) {
      changes['interval'] = {
        'old': oldRule.interval,
        'new': newRule.interval,
      };
    }

    if (oldRule.startDate != newRule.startDate) {
      changes['startDate'] = {
        'old': oldRule.startDate.toIso8601String(),
        'new': newRule.startDate.toIso8601String(),
      };
    }

    if (oldRule.endDate != newRule.endDate) {
      changes['endDate'] = {
        'old': oldRule.endDate?.toIso8601String(),
        'new': newRule.endDate?.toIso8601String(),
      };
    }

    if (oldRule.count != newRule.count) {
      changes['count'] = {
        'old': oldRule.count,
        'new': newRule.count,
      };
    }

    if (!_listEquals(oldRule.byDays, newRule.byDays)) {
      changes['byDays'] = {
        'old': oldRule.byDays.map((d) => d.name).toList(),
        'new': newRule.byDays.map((d) => d.name).toList(),
      };
    }

    if (!_listEquals(oldRule.byMonthDays, newRule.byMonthDays)) {
      changes['byMonthDays'] = {
        'old': oldRule.byMonthDays,
        'new': newRule.byMonthDays,
      };
    }

    if (!_listEquals(oldRule.byMonths, newRule.byMonths)) {
      changes['byMonths'] = {
        'old': oldRule.byMonths,
        'new': newRule.byMonths,
      };
    }

    if (oldRule.weekPosition != newRule.weekPosition) {
      changes['weekPosition'] = {
        'old': oldRule.weekPosition,
        'new': newRule.weekPosition,
      };
    }

    if (oldRule.weekParity != newRule.weekParity) {
      changes['weekParity'] = {
        'old': oldRule.weekParity?.name,
        'new': newRule.weekParity?.name,
      };
    }

    if (oldRule.preset != newRule.preset) {
      changes['preset'] = {
        'old': oldRule.preset,
        'new': newRule.preset,
      };
    }

    return changes;
  }

  /// Compara dos listas para igualdad.
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Ejecuta una operacion con lock para thread-safety.
  ///
  /// Implementa un lock simple para evitar condiciones de carrera
  /// en operaciones concurrentes.
  T _withLock<T>(T Function() operation) {
    // Esperar si hay un lock activo (spin lock simple)
    while (_isLocked) {
      // En un entorno real, usar un mecanismo de lock mas robusto
    }

    _isLocked = true;
    try {
      return operation();
    } finally {
      _isLocked = false;
    }
  }
}
