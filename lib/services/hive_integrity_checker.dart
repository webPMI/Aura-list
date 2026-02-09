/// Hive database integrity checker for data validation and recovery.
///
/// This service validates Hive boxes on app start to:
/// - Check if boxes are corrupted
/// - Attempt recovery if possible
/// - Clear corrupted boxes as last resort
/// - Log integrity issues for debugging
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../models/task_history.dart';
import '../models/user_preferences.dart';
import 'error_handler.dart';

/// Status of a single Hive box
enum BoxHealth {
  /// Box is healthy and accessible
  healthy,

  /// Box has minor issues but is usable
  degraded,

  /// Box is corrupted but recoverable
  corrupted,

  /// Box is critically corrupted, needs clearing
  critical,

  /// Box doesn't exist yet
  notFound,
}

/// Status report for a single box
class BoxStatus {
  final String boxName;
  final BoxHealth health;
  final int itemCount;
  final String? errorMessage;
  final bool wasRepaired;
  final DateTime checkedAt;

  const BoxStatus({
    required this.boxName,
    required this.health,
    this.itemCount = 0,
    this.errorMessage,
    this.wasRepaired = false,
    required this.checkedAt,
  });

  /// Whether the box is usable
  bool get isUsable =>
      health == BoxHealth.healthy || health == BoxHealth.degraded;

  /// Whether the box needs attention
  bool get needsAttention =>
      health == BoxHealth.corrupted || health == BoxHealth.critical;

  BoxStatus copyWith({
    BoxHealth? health,
    int? itemCount,
    String? errorMessage,
    bool? wasRepaired,
  }) {
    return BoxStatus(
      boxName: boxName,
      health: health ?? this.health,
      itemCount: itemCount ?? this.itemCount,
      errorMessage: errorMessage ?? this.errorMessage,
      wasRepaired: wasRepaired ?? this.wasRepaired,
      checkedAt: checkedAt,
    );
  }

  @override
  String toString() {
    return 'BoxStatus('
        'name: $boxName, '
        'health: $health, '
        'items: $itemCount, '
        'repaired: $wasRepaired)';
  }
}

/// Complete integrity report for all boxes
class IntegrityReport {
  final List<BoxStatus> boxStatuses;
  final DateTime checkedAt;
  final Duration checkDuration;
  final bool wasRepairAttempted;

  const IntegrityReport({
    required this.boxStatuses,
    required this.checkedAt,
    required this.checkDuration,
    this.wasRepairAttempted = false,
  });

  /// Whether all boxes are healthy
  bool get allHealthy => boxStatuses.every(
        (status) => status.health == BoxHealth.healthy,
      );

  /// Whether all boxes are at least usable
  bool get allUsable => boxStatuses.every((status) => status.isUsable);

  /// Get boxes that need attention
  List<BoxStatus> get problemBoxes =>
      boxStatuses.where((status) => status.needsAttention).toList();

  /// Get healthy boxes
  List<BoxStatus> get healthyBoxes => boxStatuses
      .where((status) => status.health == BoxHealth.healthy)
      .toList();

  /// Get boxes that were repaired
  List<BoxStatus> get repairedBoxes =>
      boxStatuses.where((status) => status.wasRepaired).toList();

  /// Total items across all boxes
  int get totalItems =>
      boxStatuses.fold(0, (sum, status) => sum + status.itemCount);

  @override
  String toString() {
    return 'IntegrityReport('
        'healthy: ${healthyBoxes.length}/${boxStatuses.length}, '
        'problems: ${problemBoxes.length}, '
        'repaired: ${repairedBoxes.length}, '
        'duration: ${checkDuration.inMilliseconds}ms)';
  }
}

/// Service to check and repair Hive box integrity
class HiveIntegrityChecker {
  final ErrorHandler _errorHandler;

  /// Box names to check
  final List<String> boxesToCheck;

  /// Last integrity report
  IntegrityReport? _lastReport;

  HiveIntegrityChecker({
    required ErrorHandler errorHandler,
    this.boxesToCheck = const [
      'tasks',
      'notes',
      'task_history',
      'user_prefs',
      'sync_queue',
      'notes_sync_queue',
    ],
  }) : _errorHandler = errorHandler;

  /// Get an already-open box by name, handling typed boxes properly.
  /// Returns null if the box is not open.
  ///
  /// This method returns the box with its correct type to avoid
  /// "box already open with type" errors from Hive.
  BoxBase<dynamic>? _getOpenBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }

    // Get the box with the exact type it was opened with.
    // Hive requires type matching when accessing already-open boxes.
    try {
      switch (boxName) {
        case 'tasks':
          return Hive.box<Task>(boxName);
        case 'notes':
          return Hive.box<Note>(boxName);
        case 'task_history':
          return Hive.box<TaskHistory>(boxName);
        case 'user_prefs':
          return Hive.box<UserPreferences>(boxName);
        case 'sync_queue':
          return Hive.box<Map>(boxName);
        case 'notes_sync_queue':
          return Hive.box<Map>(boxName);
        default:
          // For unknown boxes, try dynamic as fallback
          return Hive.box<dynamic>(boxName);
      }
    } catch (e) {
      // If we still can't get the box, log the error
      debugPrint('[Integrity] Could not access box $boxName: $e');
      return null;
    }
  }

  /// Get the last integrity report
  IntegrityReport? get lastReport => _lastReport;

  /// Check all registered boxes
  Future<IntegrityReport> checkAllBoxes() async {
    final startTime = DateTime.now();
    final statuses = <BoxStatus>[];

    debugPrint('[Integrity] Starting integrity check...');

    for (final boxName in boxesToCheck) {
      final status = await _checkBox(boxName);
      statuses.add(status);

      if (status.health != BoxHealth.healthy) {
        debugPrint('[Integrity] Issue found in $boxName: ${status.health}');
      }
    }

    final endTime = DateTime.now();
    final report = IntegrityReport(
      boxStatuses: statuses,
      checkedAt: startTime,
      checkDuration: endTime.difference(startTime),
    );

    _lastReport = report;
    _logReport(report);

    return report;
  }

  /// Check a single box
  Future<BoxStatus> _checkBox(String boxName) async {
    final checkedAt = DateTime.now();

    try {
      // First, check if the box is already open
      final openBox = _getOpenBox(boxName);

      if (openBox != null) {
        // Box is already open, use the existing reference
        final itemCount = openBox.length;

        // Verify readability using BoxBase methods
        final isReadable = await _verifyBoxBaseReadability(openBox);
        if (!isReadable) {
          return BoxStatus(
            boxName: boxName,
            health: BoxHealth.degraded,
            itemCount: itemCount,
            errorMessage: 'Some items may be unreadable',
            checkedAt: checkedAt,
          );
        }

        return BoxStatus(
          boxName: boxName,
          health: BoxHealth.healthy,
          itemCount: itemCount,
          checkedAt: checkedAt,
        );
      }

      // Box is not open, try to open it to check it
      try {
        // Open with the appropriate type based on box name
        final box = await _openBoxWithType(boxName);
        final itemCount = box.length;

        // Verify we can read items
        await _verifyBoxBaseReadability(box);

        return BoxStatus(
          boxName: boxName,
          health: BoxHealth.healthy,
          itemCount: itemCount,
          checkedAt: checkedAt,
        );
      } on HiveError catch (e) {
        return BoxStatus(
          boxName: boxName,
          health: BoxHealth.corrupted,
          errorMessage: e.toString(),
          checkedAt: checkedAt,
        );
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error checking box $boxName',
        stackTrace: stack,
      );

      // Determine severity based on error type
      final health = _categorizeError(e);

      return BoxStatus(
        boxName: boxName,
        health: health,
        errorMessage: e.toString(),
        checkedAt: checkedAt,
      );
    }
  }

  /// Open a box with the appropriate type based on its name.
  Future<BoxBase<dynamic>> _openBoxWithType(String boxName) async {
    switch (boxName) {
      case 'tasks':
        return await Hive.openBox<Task>(boxName);
      case 'notes':
        return await Hive.openBox<Note>(boxName);
      case 'task_history':
        return await Hive.openBox<TaskHistory>(boxName);
      case 'user_prefs':
        return await Hive.openBox<UserPreferences>(boxName);
      case 'sync_queue':
        return await Hive.openBox<Map>(boxName);
      case 'notes_sync_queue':
        return await Hive.openBox<Map>(boxName);
      default:
        return await Hive.openBox<dynamic>(boxName);
    }
  }

  /// Verify that box contents are readable (works with BoxBase).
  Future<bool> _verifyBoxBaseReadability(BoxBase<dynamic> box) async {
    try {
      // BoxBase doesn't have get(), so we cast to Box if possible
      if (box is! Box) {
        // For LazyBox or other types, just check if we can access keys
        for (var i = 0; i < box.length; i++) {
          box.keyAt(i);
        }
        return true;
      }

      // Try to iterate through all items
      int readableCount = 0;
      int totalCount = box.length;

      for (var i = 0; i < totalCount; i++) {
        try {
          final key = box.keyAt(i);
          box.get(key);
          readableCount++;
        } catch (e) {
          debugPrint('[Integrity] Unreadable item at index $i in ${box.name}');
        }
      }

      return readableCount == totalCount;
    } catch (e) {
      return false;
    }
  }

  /// Categorize error to determine box health
  BoxHealth _categorizeError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('corrupt') || errorStr.contains('invalid')) {
      return BoxHealth.corrupted;
    }

    if (errorStr.contains('not found') || errorStr.contains('does not exist')) {
      return BoxHealth.notFound;
    }

    if (errorStr.contains('type') || errorStr.contains('adapter')) {
      return BoxHealth.degraded;
    }

    return BoxHealth.critical;
  }

  /// Attempt to repair a corrupted box
  Future<bool> repairBox(String boxName) async {
    debugPrint('[Integrity] Attempting to repair box: $boxName');

    try {
      // First, try to compact the box if it's open
      final openBox = _getOpenBox(boxName);
      if (openBox != null) {
        try {
          await openBox.compact();
          debugPrint('[Integrity] Compacted box: $boxName');

          // Re-check after compaction
          final status = await _checkBox(boxName);
          if (status.health == BoxHealth.healthy) {
            debugPrint('[Integrity] Box repaired after compaction: $boxName');
            return true;
          }
        } catch (e) {
          debugPrint('[Integrity] Compaction failed: $e');
        }
      }

      // Try to delete corrupted entries
      try {
        final box = _getOpenBox(boxName);
        if (box != null && box is Box) {
          final keysToDelete = <dynamic>[];

          for (var i = 0; i < box.length; i++) {
            try {
              final key = box.keyAt(i);
              box.get(key); // Test if readable
            } catch (e) {
              final key = box.keyAt(i);
              keysToDelete.add(key);
            }
          }

          if (keysToDelete.isNotEmpty) {
            for (final key in keysToDelete) {
              await box.delete(key);
            }
            debugPrint(
                '[Integrity] Deleted ${keysToDelete.length} corrupted entries');
            return true;
          }
        }
      } catch (e) {
        debugPrint('[Integrity] Selective deletion failed: $e');
      }

      debugPrint('[Integrity] Could not repair box: $boxName');
      return false;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Failed to repair box $boxName',
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Clear a corrupted box (last resort)
  Future<void> clearCorruptedBox(String boxName) async {
    debugPrint('[Integrity] Clearing corrupted box: $boxName');

    try {
      final openBox = _getOpenBox(boxName);
      if (openBox != null) {
        await openBox.clear();
        debugPrint('[Integrity] Box cleared: $boxName');
      } else {
        // Delete the box file
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('[Integrity] Box file deleted: $boxName');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.critical,
        message: 'Failed to clear corrupted box $boxName',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Run automatic repair on all boxes
  Future<IntegrityReport> repairAllBoxes() async {
    final startTime = DateTime.now();
    final statuses = <BoxStatus>[];

    debugPrint('[Integrity] Starting automatic repair...');

    for (final boxName in boxesToCheck) {
      var status = await _checkBox(boxName);

      if (status.health == BoxHealth.corrupted ||
          status.health == BoxHealth.degraded) {
        final repaired = await repairBox(boxName);
        if (repaired) {
          status = await _checkBox(boxName);
          status = status.copyWith(wasRepaired: true);
        }
      }

      if (status.health == BoxHealth.critical) {
        // Last resort: clear the box
        try {
          await clearCorruptedBox(boxName);
          status = BoxStatus(
            boxName: boxName,
            health: BoxHealth.healthy,
            itemCount: 0,
            wasRepaired: true,
            errorMessage: 'Box was cleared due to critical corruption',
            checkedAt: DateTime.now(),
          );
        } catch (e) {
          // Could not even clear the box
          status = status.copyWith(
            errorMessage: 'Critical: Could not clear corrupted box',
          );
        }
      }

      statuses.add(status);
    }

    final endTime = DateTime.now();
    final report = IntegrityReport(
      boxStatuses: statuses,
      checkedAt: startTime,
      checkDuration: endTime.difference(startTime),
      wasRepairAttempted: true,
    );

    _lastReport = report;
    _logReport(report);

    return report;
  }

  /// Log the integrity report
  void _logReport(IntegrityReport report) {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('=== Hive Integrity Report ===');
    debugPrint('Checked at: ${report.checkedAt}');
    debugPrint('Duration: ${report.checkDuration.inMilliseconds}ms');
    debugPrint('Total boxes: ${report.boxStatuses.length}');
    debugPrint('Healthy: ${report.healthyBoxes.length}');
    debugPrint('Problems: ${report.problemBoxes.length}');
    debugPrint('Repaired: ${report.repairedBoxes.length}');
    debugPrint('Total items: ${report.totalItems}');

    if (report.problemBoxes.isNotEmpty) {
      debugPrint('--- Problem Boxes ---');
      for (final box in report.problemBoxes) {
        debugPrint('  ${box.boxName}: ${box.health} - ${box.errorMessage}');
      }
    }

    debugPrint('=============================');
    debugPrint('');
  }

  /// Get a summary string
  String getSummary() {
    final report = _lastReport;
    if (report == null) {
      return 'No integrity check performed yet';
    }

    if (report.allHealthy) {
      return 'All ${report.boxStatuses.length} boxes healthy (${report.totalItems} items)';
    }

    final problems = report.problemBoxes.length;
    return '$problems box(es) need attention, ${report.healthyBoxes.length} healthy';
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for Hive integrity checker
final hiveIntegrityCheckerProvider = Provider<HiveIntegrityChecker>((ref) {
  final errorHandler = ref.watch(errorHandlerProvider);
  return HiveIntegrityChecker(errorHandler: errorHandler);
});

/// Provider for the last integrity report
final integrityReportProvider = FutureProvider<IntegrityReport>((ref) async {
  final checker = ref.watch(hiveIntegrityCheckerProvider);
  return checker.checkAllBoxes();
});

/// Provider to check if all boxes are healthy
final allBoxesHealthyProvider = Provider<bool>((ref) {
  final checker = ref.watch(hiveIntegrityCheckerProvider);
  return checker.lastReport?.allHealthy ?? true;
});
