import 'package:hive/hive.dart';

part 'sync_metadata.g.dart';

/// Modelo para rastrear el estado de sincronizacion de cada registro.
///
/// Este modelo mantiene metadatos sobre la sincronizacion entre
/// Hive local y Firebase Cloud, permitiendo:
/// - Deteccion de conflictos
/// - Seguimiento de intentos de sincronizacion
/// - Gestion de errores de sincronizacion
@HiveType(typeId: 5)
class SyncMetadata extends HiveObject {
  /// ID unico del registro (task.key o note.key como string)
  @HiveField(0)
  late String recordId;

  /// Tipo de registro: 'task' o 'note'
  @HiveField(1)
  late String recordType;

  /// Ultima actualizacion local
  @HiveField(2)
  late DateTime lastLocalUpdate;

  /// Ultima sincronizacion exitosa con la nube
  @HiveField(3)
  DateTime? lastCloudSync;

  /// Si hay cambios pendientes de sincronizar
  @HiveField(4)
  late bool isPendingSync;

  /// Si existe un conflicto sin resolver
  @HiveField(5)
  late bool hasConflict;

  /// Numero de intentos de sincronizacion fallidos
  @HiveField(6)
  late int syncAttempts;

  /// Ultimo error de sincronizacion
  @HiveField(7)
  String? lastSyncError;

  /// Timestamp de la version remota en el momento del conflicto
  @HiveField(8)
  DateTime? remoteVersionAt;

  /// Checksum del contenido local para deteccion de cambios
  @HiveField(9)
  String? localChecksum;

  SyncMetadata({
    required this.recordId,
    required this.recordType,
    required this.lastLocalUpdate,
    this.lastCloudSync,
    this.isPendingSync = true,
    this.hasConflict = false,
    this.syncAttempts = 0,
    this.lastSyncError,
    this.remoteVersionAt,
    this.localChecksum,
  });

  /// Crea metadatos para una tarea nueva
  factory SyncMetadata.forTask(String taskId) {
    return SyncMetadata(
      recordId: taskId,
      recordType: 'task',
      lastLocalUpdate: DateTime.now(),
    );
  }

  /// Crea metadatos para una nota nueva
  factory SyncMetadata.forNote(String noteId) {
    return SyncMetadata(
      recordId: noteId,
      recordType: 'note',
      lastLocalUpdate: DateTime.now(),
    );
  }

  /// Genera una clave unica para este registro
  String get metadataKey => '${recordType}_$recordId';

  /// Verifica si la sincronizacion esta atrasada (mas de 1 hora)
  bool get isSyncStale {
    if (lastCloudSync == null) return true;
    return DateTime.now().difference(lastCloudSync!).inHours > 1;
  }

  /// Verifica si se han excedido los reintentos maximos
  bool get hasExceededMaxRetries => syncAttempts >= 5;

  /// Marca como sincronizado exitosamente
  void markSynced() {
    lastCloudSync = DateTime.now();
    isPendingSync = false;
    hasConflict = false;
    syncAttempts = 0;
    lastSyncError = null;
    remoteVersionAt = null;
  }

  /// Marca como pendiente de sincronizacion
  void markPending() {
    lastLocalUpdate = DateTime.now();
    isPendingSync = true;
  }

  /// Registra un intento de sincronizacion fallido
  void recordSyncFailure(String error) {
    syncAttempts++;
    lastSyncError = error;
  }

  /// Marca un conflicto detectado
  void markConflict(DateTime remoteTimestamp) {
    hasConflict = true;
    remoteVersionAt = remoteTimestamp;
  }

  /// Resuelve el conflicto
  void resolveConflict() {
    hasConflict = false;
    remoteVersionAt = null;
  }

  /// Reinicia el contador de intentos
  void resetRetries() {
    syncAttempts = 0;
    lastSyncError = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'recordType': recordType,
      'lastLocalUpdate': lastLocalUpdate.toIso8601String(),
      'lastCloudSync': lastCloudSync?.toIso8601String(),
      'isPendingSync': isPendingSync,
      'hasConflict': hasConflict,
      'syncAttempts': syncAttempts,
      'lastSyncError': lastSyncError,
      'remoteVersionAt': remoteVersionAt?.toIso8601String(),
      'localChecksum': localChecksum,
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      recordId: json['recordId'] as String,
      recordType: json['recordType'] as String,
      lastLocalUpdate: DateTime.parse(json['lastLocalUpdate'] as String),
      lastCloudSync: json['lastCloudSync'] != null
          ? DateTime.parse(json['lastCloudSync'] as String)
          : null,
      isPendingSync: json['isPendingSync'] as bool? ?? true,
      hasConflict: json['hasConflict'] as bool? ?? false,
      syncAttempts: json['syncAttempts'] as int? ?? 0,
      lastSyncError: json['lastSyncError'] as String?,
      remoteVersionAt: json['remoteVersionAt'] != null
          ? DateTime.parse(json['remoteVersionAt'] as String)
          : null,
      localChecksum: json['localChecksum'] as String?,
    );
  }

  SyncMetadata copyWith({
    String? recordId,
    String? recordType,
    DateTime? lastLocalUpdate,
    DateTime? lastCloudSync,
    bool? isPendingSync,
    bool? hasConflict,
    int? syncAttempts,
    String? lastSyncError,
    DateTime? remoteVersionAt,
    String? localChecksum,
  }) {
    return SyncMetadata(
      recordId: recordId ?? this.recordId,
      recordType: recordType ?? this.recordType,
      lastLocalUpdate: lastLocalUpdate ?? this.lastLocalUpdate,
      lastCloudSync: lastCloudSync ?? this.lastCloudSync,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      hasConflict: hasConflict ?? this.hasConflict,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      remoteVersionAt: remoteVersionAt ?? this.remoteVersionAt,
      localChecksum: localChecksum ?? this.localChecksum,
    );
  }

  @override
  String toString() {
    return 'SyncMetadata(recordId: $recordId, recordType: $recordType, '
        'isPendingSync: $isPendingSync, hasConflict: $hasConflict, '
        'syncAttempts: $syncAttempts)';
  }
}
