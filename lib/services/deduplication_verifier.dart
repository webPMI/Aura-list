import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import 'logger_service.dart';

/// Utility class to verify and diagnose task/note duplication issues
/// This is a diagnostic tool to be used during development and debugging
class DeduplicationVerifier {
  static final _logger = LoggerService();
  /// Check for duplicate tasks in the Hive box
  /// Returns a report with duplicate information
  static Future<DuplicationReport> checkTaskDuplicates(
    Box<Task> taskBox,
  ) async {
    final report = DuplicationReport(type: 'Tasks');

    // Track seen identifiers
    final seenFirestoreIds = <String, List<dynamic>>{};
    final seenHiveKeys = <dynamic, int>{};
    final seenTimestamps = <int, List<dynamic>>{};

    // Analyze all tasks
    for (final entry in taskBox.toMap().entries) {
      final key = entry.key;
      final task = entry.value;

      report.totalItems++;

      // Check firestoreId duplicates
      if (task.firestoreId.isNotEmpty) {
        if (seenFirestoreIds.containsKey(task.firestoreId)) {
          seenFirestoreIds[task.firestoreId]!.add(key);
          report.duplicatesByFirestoreId++;
        } else {
          seenFirestoreIds[task.firestoreId] = [key];
        }
      }

      // Check Hive key duplicates (should never happen, but check anyway)
      if (seenHiveKeys.containsKey(key)) {
        report.duplicatesByHiveKey++;
        _logger.debug('Service', '⚠️ CRÍTICO: Hive key duplicado detectado: $key');
      }
      seenHiveKeys[key] = 1;

      // Check timestamp duplicates
      final timestamp = task.createdAt.millisecondsSinceEpoch;
      if (seenTimestamps.containsKey(timestamp)) {
        seenTimestamps[timestamp]!.add(key);
        report.duplicatesByTimestamp++;
      } else {
        seenTimestamps[timestamp] = [key];
      }
    }

    // Store duplicate details
    seenFirestoreIds.forEach((firestoreId, keys) {
      if (keys.length > 1) {
        report.firestoreIdDuplicates[firestoreId] = keys;
      }
    });

    seenTimestamps.forEach((timestamp, keys) {
      if (keys.length > 1) {
        report.timestampDuplicates[timestamp] = keys;
      }
    });

    return report;
  }

  /// Check for duplicate notes in the Hive box
  static Future<DuplicationReport> checkNoteDuplicates(
    Box<Note> noteBox,
  ) async {
    final report = DuplicationReport(type: 'Notes');

    final seenFirestoreIds = <String, List<dynamic>>{};
    final seenHiveKeys = <dynamic, int>{};
    final seenTimestamps = <int, List<dynamic>>{};

    for (final entry in noteBox.toMap().entries) {
      final key = entry.key;
      final note = entry.value;

      report.totalItems++;

      // Check firestoreId duplicates
      if (note.firestoreId.isNotEmpty) {
        if (seenFirestoreIds.containsKey(note.firestoreId)) {
          seenFirestoreIds[note.firestoreId]!.add(key);
          report.duplicatesByFirestoreId++;
        } else {
          seenFirestoreIds[note.firestoreId] = [key];
        }
      }

      // Check Hive key duplicates
      if (seenHiveKeys.containsKey(key)) {
        report.duplicatesByHiveKey++;
        _logger.debug('Service', '⚠️ CRÍTICO: Hive key duplicado detectado: $key');
      }
      seenHiveKeys[key] = 1;

      // Check timestamp duplicates
      final timestamp = note.createdAt.millisecondsSinceEpoch;
      if (seenTimestamps.containsKey(timestamp)) {
        seenTimestamps[timestamp]!.add(key);
        report.duplicatesByTimestamp++;
      } else {
        seenTimestamps[timestamp] = [key];
      }
    }

    // Store duplicate details
    seenFirestoreIds.forEach((firestoreId, keys) {
      if (keys.length > 1) {
        report.firestoreIdDuplicates[firestoreId] = keys;
      }
    });

    seenTimestamps.forEach((timestamp, keys) {
      if (keys.length > 1) {
        report.timestampDuplicates[timestamp] = keys;
      }
    });

    return report;
  }

  /// Print a detailed report of duplicates
  static void printReport(DuplicationReport report) {    _logger.debug('Service', '========================================');
    _logger.debug('Service', '  REPORTE DE DUPLICACIÓN: ${report.type}');
    _logger.debug('Service', '========================================');
    _logger.debug('Service', 'Total de items: ${report.totalItems}');    if (report.hasDuplicates) {
      _logger.debug('Service', '⚠️ SE ENCONTRARON DUPLICADOS:');      if (report.duplicatesByFirestoreId > 0) {
        _logger.debug('Service', '  - Por firestoreId: ${report.duplicatesByFirestoreId} duplicados');
        report.firestoreIdDuplicates.forEach((firestoreId, keys) {
          _logger.debug('Service', '    → $firestoreId: ${keys.length} copias (keys: $keys)');
        });
      }

      if (report.duplicatesByHiveKey > 0) {
        _logger.debug('Service', '  - Por Hive key: ${report.duplicatesByHiveKey} duplicados (CRÍTICO)');
      }

      if (report.duplicatesByTimestamp > 0) {
        _logger.debug('Service', '  - Por timestamp: ${report.duplicatesByTimestamp} duplicados');
        report.timestampDuplicates.forEach((timestamp, keys) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          _logger.debug('Service', '    → $date: ${keys.length} copias (keys: $keys)');
        });
      }      _logger.debug('Service', '🔧 RECOMENDACIÓN:');
      _logger.debug('Service', '   Ejecutar DatabaseService._cleanupDuplicates() para limpiar.');
    } else {
      _logger.debug('Service', '✅ NO SE ENCONTRARON DUPLICADOS');
      _logger.debug('Service', '   La base de datos está limpia.');
    }

    _logger.debug('Service', '========================================');  }

  /// Run a full verification of all boxes
  static Future<void> verifyAllBoxes(
    Box<Task> taskBox,
    Box<Note> noteBox,
  ) async {
    _logger.debug('Service', '🔍 Iniciando verificación de duplicados...');    // Check tasks
    final taskReport = await checkTaskDuplicates(taskBox);
    printReport(taskReport);

    // Check notes
    final noteReport = await checkNoteDuplicates(noteBox);
    printReport(noteReport);

    // Summary
    if (taskReport.hasDuplicates || noteReport.hasDuplicates) {
      _logger.debug('Service', '⚠️ RESUMEN: Se encontraron duplicados en la base de datos.');
      _logger.debug('Service', '   Total de duplicados: ${taskReport.totalDuplicates + noteReport.totalDuplicates}');
    } else {
      _logger.debug('Service', '✅ RESUMEN: Base de datos completamente limpia.');
      _logger.debug('Service', '   No se encontraron duplicados en ninguna colección.');
    }
  }

  /// Get detailed information about a specific task
  static String getTaskIdentityInfo(Task task) {
    return '''
Task Identity:
  - Title: "${task.title}"
  - Hive Key: ${task.key ?? 'null'}
  - Firestore ID: ${task.firestoreId.isEmpty ? 'empty' : task.firestoreId}
  - Created At: ${task.createdAt} (${task.createdAt.millisecondsSinceEpoch})
  - Last Updated: ${task.lastUpdatedAt ?? 'null'}
  - Type: ${task.type}
  - isInBox: ${task.isInBox}
''';
  }

  /// Get detailed information about a specific note
  static String getNoteIdentityInfo(Note note) {
    return '''
Note Identity:
  - Title: "${note.title}"
  - Hive Key: ${note.key ?? 'null'}
  - Firestore ID: ${note.firestoreId.isEmpty ? 'empty' : note.firestoreId}
  - Created At: ${note.createdAt} (${note.createdAt.millisecondsSinceEpoch})
  - Updated At: ${note.updatedAt}
  - isInBox: ${note.isInBox}
''';
  }

  /// Compare two tasks to see if they are duplicates
  static bool areTasksDuplicates(Task task1, Task task2) {
    // Same Hive key = definitely same task
    if (task1.key != null && task2.key != null && task1.key == task2.key) {
      return false; // Same object
    }

    // Same firestoreId = duplicate
    if (task1.firestoreId.isNotEmpty &&
        task2.firestoreId.isNotEmpty &&
        task1.firestoreId == task2.firestoreId) {
      return true;
    }

    // Same timestamp = likely duplicate (especially if same title)
    if (task1.createdAt.millisecondsSinceEpoch ==
        task2.createdAt.millisecondsSinceEpoch) {
      return task1.title == task2.title;
    }

    return false;
  }

  /// Compare two notes to see if they are duplicates
  static bool areNotesDuplicates(Note note1, Note note2) {
    // Same Hive key = definitely same note
    if (note1.key != null && note2.key != null && note1.key == note2.key) {
      return false; // Same object
    }

    // Same firestoreId = duplicate
    if (note1.firestoreId.isNotEmpty &&
        note2.firestoreId.isNotEmpty &&
        note1.firestoreId == note2.firestoreId) {
      return true;
    }

    // Same timestamp = likely duplicate (especially if same title)
    if (note1.createdAt.millisecondsSinceEpoch ==
        note2.createdAt.millisecondsSinceEpoch) {
      return note1.title == note2.title;
    }

    return false;
  }
}

/// Report class containing duplication analysis results
class DuplicationReport {
  final String type; // 'Tasks' or 'Notes'
  int totalItems = 0;
  int duplicatesByFirestoreId = 0;
  int duplicatesByHiveKey = 0;
  int duplicatesByTimestamp = 0;

  // Detailed duplicate information
  final Map<String, List<dynamic>> firestoreIdDuplicates = {};
  final Map<int, List<dynamic>> timestampDuplicates = {};

  DuplicationReport({required this.type});

  bool get hasDuplicates =>
      duplicatesByFirestoreId > 0 ||
      duplicatesByHiveKey > 0 ||
      duplicatesByTimestamp > 0;

  int get totalDuplicates =>
      duplicatesByFirestoreId +
      duplicatesByHiveKey +
      duplicatesByTimestamp;

  /// Get a summary string
  String get summary {
    if (!hasDuplicates) {
      return '$type: No duplicates found ($totalItems items)';
    }
    return '$type: $totalDuplicates duplicates found ($totalItems items total)';
  }
}
