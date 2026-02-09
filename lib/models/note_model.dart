import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  late String firestoreId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  String? taskId; // null = independent note, otherwise linked to task.key

  @HiveField(6)
  late String color; // Hex color for note card (e.g., '#FFFDE7')

  @HiveField(7)
  late bool isPinned;

  @HiveField(8)
  late List<String> tags; // For categorization/filtering

  @HiveField(9, defaultValue: false)
  bool deleted; // Soft delete flag

  @HiveField(10)
  DateTime? deletedAt; // Timestamp de borrado

  Note({
    this.firestoreId = '',
    required this.title,
    this.content = '',
    required this.createdAt,
    DateTime? updatedAt,
    this.taskId,
    this.color = '#FFFFFF',
    this.isPinned = false,
    List<String>? tags,
    this.deleted = false,
    this.deletedAt,
  })  : updatedAt = updatedAt ?? createdAt,
        tags = tags ?? [];

  // For compatibility with existing code
  int get id => key ?? 0;

  // Check if note is linked to a task
  bool get isLinkedToTask => taskId != null && taskId!.isNotEmpty;

  // Get preview of content (first 100 chars)
  String get contentPreview {
    if (content.isEmpty) return '';
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'taskId': taskId,
      'color': color,
      'isPinned': isPinned,
      'tags': tags,
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Note.fromFirestore(String id, Map<String, dynamic> data) {
    return Note(
      firestoreId: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
      taskId: data['taskId'],
      color: data['color'] ?? '#FFFFFF',
      isPinned: data['isPinned'] ?? false,
      tags: (data['tags'] as List?)?.cast<String>() ?? [],
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
    );
  }

  /// Crea una nueva instancia con los campos modificados (inmutable).
  /// Usar este metodo cuando se necesita una copia sin modificar el original.
  Note copyWith({
    String? firestoreId,
    String? title,
    String? content,
    DateTime? updatedAt,
    String? taskId,
    bool clearTaskId = false,
    String? color,
    bool? isPinned,
    List<String>? tags,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return Note(
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? List.from(this.tags),
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Actualiza los campos in-place cuando el objeto esta en Hive.
  /// Usar este metodo para modificar un objeto que ya esta guardado.
  void updateInPlace({
    String? firestoreId,
    String? title,
    String? content,
    DateTime? updatedAt,
    String? taskId,
    bool clearTaskId = false,
    String? color,
    bool? isPinned,
    List<String>? tags,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    if (firestoreId != null) this.firestoreId = firestoreId;
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    this.updatedAt = updatedAt ?? DateTime.now();
    if (clearTaskId) {
      this.taskId = null;
    } else if (taskId != null) {
      this.taskId = taskId;
    }
    if (color != null) this.color = color;
    if (isPinned != null) this.isPinned = isPinned;
    if (tags != null) this.tags = tags;
    if (deleted != null) this.deleted = deleted;
    if (deletedAt != null) this.deletedAt = deletedAt;
  }

  // Predefined color options (Material Design pastels)
  static const Map<String, String> colorOptions = {
    'Blanco': '#FFFFFF',
    'Amarillo': '#FFFDE7',
    'Verde': '#E8F5E9',
    'Azul': '#E3F2FD',
    'Rosa': '#FCE4EC',
    'Naranja': '#FFF3E0',
    'Morado': '#F3E5F5',
    'Gris': '#ECEFF1',
  };

  // Get color name from hex
  static String getColorName(String hex) {
    for (final entry in colorOptions.entries) {
      if (entry.value == hex) return entry.key;
    }
    return 'Blanco';
  }

  // Create a quick note with auto-generated title
  factory Note.quick(String content, {String? taskId}) {
    final lines = content.split('\n');
    final firstLine = lines.first.trim();
    final title = firstLine.length > 50
        ? '${firstLine.substring(0, 47)}...'
        : firstLine;

    return Note(
      title: title.isNotEmpty ? title : 'Nota rapida',
      content: content,
      createdAt: DateTime.now(),
      taskId: taskId,
      color: taskId != null ? '#FFFDE7' : '#FFFFFF', // Yellow for task notes
    );
  }
}
