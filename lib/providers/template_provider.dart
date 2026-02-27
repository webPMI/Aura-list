import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_template.dart';
import '../services/error_handler.dart';
import '../services/logger_service.dart';

const _uuid = Uuid();

/// Service for managing task templates
class TemplateService {
  static const String _boxName = 'task_templates';
  final ErrorHandler _errorHandler;
  final _logger = LoggerService();
  Box<TaskTemplate>? _box;

  TemplateService(this._errorHandler);

  /// Initialize the service
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<TaskTemplate>(_boxName);
      } else {
        _box = await Hive.openBox<TaskTemplate>(_boxName);
      }
      _logger.debug('Service', '[TemplateService] Initialized');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al inicializar servicio de plantillas',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get all templates
  Future<List<TaskTemplate>> getAll() async {
    await init();
    try {
      return _box?.values.toList() ?? [];
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al obtener plantillas',
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Watch all templates
  Stream<List<TaskTemplate>> watchAll() async* {
    await init();

    List<TaskTemplate> getTemplates() {
      return _box?.values.toList() ?? [];
    }

    yield getTemplates();

    if (_box != null) {
      await for (final _ in _box!.watch()) {
        yield getTemplates();
      }
    }
  }

  /// Get templates by type
  Future<List<TaskTemplate>> getByType(String type) async {
    final all = await getAll();
    return all.where((t) => t.taskType == type).toList();
  }

  /// Create a new template
  Future<TaskTemplate> create(TaskTemplate template) async {
    await init();
    try {
      // Ensure template has an ID
      if (template.id.isEmpty) {
        template = template.copyWith(id: _uuid.v4());
      }

      template.lastUpdatedAt = DateTime.now();
      await _box?.add(template);

      _logger.debug('Service', '[TemplateService] Created template: ${template.name}');
      return template;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al crear plantilla',
        userMessage: 'No se pudo guardar la plantilla',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Update an existing template
  Future<void> update(TaskTemplate template) async {
    await init();
    try {
      template.lastUpdatedAt = DateTime.now();

      if (template.isInBox) {
        await template.save();
      } else {
        await _box?.add(template);
      }

      _logger.debug('Service', '[TemplateService] Updated template: ${template.name}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al actualizar plantilla',
        userMessage: 'No se pudo actualizar la plantilla',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Delete a template
  Future<void> delete(TaskTemplate template) async {
    await init();
    try {
      if (template.isInBox) {
        await template.delete();
      }

      _logger.debug('Service', '[TemplateService] Deleted template: ${template.name}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.error,
        message: 'Error al eliminar plantilla',
        userMessage: 'No se pudo eliminar la plantilla',
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Use a template (increment usage count)
  Future<TaskTemplate> use(TaskTemplate template) async {
    await init();
    try {
      template.markAsUsed();
      if (template.isInBox) {
        await template.save();
      }

      _logger.debug('Service', '[TemplateService] Used template: ${template.name}');
      return template;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al marcar plantilla como usada',
        stackTrace: stack,
      );
      return template;
    }
  }

  /// Toggle pin status
  Future<void> togglePin(TaskTemplate template) async {
    await init();
    try {
      final updated = template.copyWith(
        isPinned: !template.isPinned,
        lastUpdatedAt: DateTime.now(),
      );

      if (template.isInBox) {
        final key = template.key;
        await template.delete();
        await _box?.put(key, updated);
      } else {
        await _box?.add(updated);
      }

      _logger.debug('Service', '[TemplateService] Toggled pin: ${template.name}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        severity: ErrorSeverity.warning,
        message: 'Error al fijar/desfijar plantilla',
        stackTrace: stack,
      );
    }
  }

  /// Sync template to Firestore
  Future<void> syncToFirestore(TaskTemplate template, String userId) async {
    if (userId.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('task_templates')
          .doc(template.id);

      await docRef.set(template.toFirestore(), SetOptions(merge: true));

      _logger.debug('Service', '[TemplateService] Synced to Firestore: ${template.name}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar plantilla con Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Delete template from Firestore
  Future<void> deleteFromFirestore(String templateId, String userId) async {
    if (userId.isEmpty || templateId.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(userId)
          .collection('task_templates')
          .doc(templateId)
          .delete();

      _logger.debug('Service', '[TemplateService] Deleted from Firestore: $templateId');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al eliminar plantilla de Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Sync from Firestore
  Future<void> syncFromFirestore(String userId) async {
    if (userId.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('task_templates')
          .get();

      for (final doc in snapshot.docs) {
        try {
          final template = TaskTemplate.fromFirestore(doc.id, doc.data());

          // Check if template exists locally
          final existingTemplate = _box?.values
              .where((t) => t.id == template.id)
              .firstOrNull;

          if (existingTemplate != null) {
            // Update if remote is newer
            if (template.lastUpdatedAt != null &&
                (existingTemplate.lastUpdatedAt == null ||
                    template.lastUpdatedAt!.isAfter(existingTemplate.lastUpdatedAt!))) {
              await existingTemplate.delete();
              await _box?.add(template);
            }
          } else {
            // Add new template
            await _box?.add(template);
          }
        } catch (e) {
          _logger.warning('TemplateService', 'Error al procesar plantilla: ${doc.id}');
        }
      }

      _logger.debug('Service', '[TemplateService] Synced from Firestore');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al sincronizar plantillas desde Firebase',
        stackTrace: stack,
      );
    }
  }

  /// Close the box
  Future<void> close() async {
    if (_box?.isOpen ?? false) {
      await _box?.close();
    }
  }
}

/// Notifier for managing templates state
class TemplateNotifier extends StateNotifier<List<TaskTemplate>> {
  final TemplateService _service;

  TemplateNotifier(this._service) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    _loadTemplates();
    _watchTemplates();
  }

  Future<void> _loadTemplates() async {
    state = await _service.getAll();
  }

  void _watchTemplates() {
    _service.watchAll().listen((templates) {
      state = templates;
    });
  }

  Future<void> createTemplate(TaskTemplate template) async {
    await _service.create(template);
  }

  Future<void> updateTemplate(TaskTemplate template) async {
    await _service.update(template);
  }

  Future<void> deleteTemplate(TaskTemplate template) async {
    await _service.delete(template);
  }

  Future<TaskTemplate> useTemplate(TaskTemplate template) async {
    return await _service.use(template);
  }

  Future<void> togglePin(TaskTemplate template) async {
    await _service.togglePin(template);
  }

  Future<void> syncToCloud(TaskTemplate template, String userId) async {
    await _service.syncToFirestore(template, userId);
  }

  Future<void> syncFromCloud(String userId) async {
    await _service.syncFromFirestore(userId);
  }
}

// Providers
final templateServiceProvider = Provider<TemplateService>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return TemplateService(errorHandler);
});

final templatesProvider = StateNotifierProvider<TemplateNotifier, List<TaskTemplate>>((ref) {
  final service = ref.watch(templateServiceProvider);
  return TemplateNotifier(service);
});

/// Provider for templates filtered by type
final templatesByTypeProvider = Provider.family<List<TaskTemplate>, String>((ref, type) {
  final templates = ref.watch(templatesProvider);
  return templates.where((t) => t.taskType == type).toList()
    ..sort((a, b) {
      // Sort by: pinned first, then by usage count, then by last used
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;

      if (a.lastUsedAt != null && b.lastUsedAt != null) {
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      }

      return b.createdAt.compareTo(a.createdAt);
    });
});

/// Provider for search query
final templateSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered templates based on search query
final filteredTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templates = ref.watch(templatesProvider);
  final query = ref.watch(templateSearchQueryProvider);

  if (query.isEmpty) {
    return templates
      ..sort((a, b) {
        // Sort by: pinned first, then by usage count, then by last used
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        final usageCompare = b.usageCount.compareTo(a.usageCount);
        if (usageCompare != 0) return usageCompare;

        if (a.lastUsedAt != null && b.lastUsedAt != null) {
          return b.lastUsedAt!.compareTo(a.lastUsedAt!);
        }

        return b.createdAt.compareTo(a.createdAt);
      });
  }

  return templates.where((t) => t.matchesQuery(query)).toList()
    ..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;

      if (a.lastUsedAt != null && b.lastUsedAt != null) {
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      }

      return b.createdAt.compareTo(a.createdAt);
    });
});
