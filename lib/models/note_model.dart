import 'dart:convert';
import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 7)
class ChecklistItem {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String text;

  @HiveField(2)
  late bool isCompleted;

  @HiveField(3)
  late int order;

  ChecklistItem({
    String? id,
    required this.text,
    this.isCompleted = false,
    this.order = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  ChecklistItem copyWith({String? text, bool? isCompleted, int? order}) {
    return ChecklistItem(
      id: id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'isCompleted': isCompleted,
    'order': order,
  };

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
    id: map['id'],
    text: map['text'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    order: map['order'] ?? 0,
  );
}

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

  @HiveField(11, defaultValue: [])
  List<ChecklistItem> checklist;

  @HiveField(12)
  String? notebookId; // null = sin carpeta, ID del notebook al que pertenece

  @HiveField(13, defaultValue: 'active')
  late String status; // 'active', 'archived', 'deleted'

  @HiveField(14)
  String? richContent; // Quill Delta JSON for rich text

  @HiveField(15, defaultValue: 'plain')
  late String contentType; // 'plain', 'checklist', or 'rich'

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
    List<ChecklistItem>? checklist,
    this.notebookId,
    this.status = 'active',
    this.richContent,
    this.contentType = 'plain',
  }) : updatedAt = updatedAt ?? createdAt,
       tags = tags ?? [],
       checklist = checklist ?? [];

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

  // Checklist helpers
  bool get hasChecklist => checklist.isNotEmpty;
  int get checklistCompleted =>
      checklist.where((item) => item.isCompleted).length;
  int get checklistTotal => checklist.length;
  double get checklistProgress =>
      checklistTotal > 0 ? checklistCompleted / checklistTotal : 0;
  String get checklistProgressText => '$checklistCompleted/$checklistTotal';

  // Status convenience getters
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';
  bool get isDeleted => status == 'deleted' || deleted;

  // Rich text helpers
  bool get isRichText => contentType == 'rich' && richContent != null;
  bool get isPlainText => contentType == 'plain';
  bool get isChecklistType => contentType == 'checklist';

  // Get display content for previews (extracts plain text from rich content)
  String get displayContent {
    if (isRichText && richContent != null) {
      return _extractPlainTextFromDelta(richContent!);
    }
    return content;
  }

  // Extract plain text from Quill Delta JSON for preview
  static String _extractPlainTextFromDelta(String deltaJson) {
    try {
      final decoded = jsonDecode(deltaJson);
      final List<dynamic> ops = (decoded is List)
          ? decoded
          : ((decoded as Map<String, dynamic>)['ops'] as List?) ?? [];
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      return '';
    }
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
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'notebookId': notebookId,
      'status': status,
      'richContent': richContent,
      'contentType': contentType,
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
      deletedAt: data['deletedAt'] != null
          ? DateTime.parse(data['deletedAt'])
          : null,
      checklist:
          (data['checklist'] as List?)
              ?.map(
                (item) => ChecklistItem.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      notebookId: data['notebookId'],
      status: data['status'] ?? 'active',
      richContent: data['richContent'],
      contentType: data['contentType'] ?? 'plain',
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
    List<ChecklistItem>? checklist,
    String? notebookId,
    bool clearNotebookId = false,
    String? status,
    String? richContent,
    bool clearRichContent = false,
    String? contentType,
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
      checklist: checklist ?? List.from(this.checklist),
      notebookId: clearNotebookId ? null : (notebookId ?? this.notebookId),
      status: status ?? this.status,
      richContent: clearRichContent ? null : (richContent ?? this.richContent),
      contentType: contentType ?? this.contentType,
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
    List<ChecklistItem>? checklist,
    String? notebookId,
    bool clearNotebookId = false,
    String? status,
    String? richContent,
    bool clearRichContent = false,
    String? contentType,
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
    if (checklist != null) this.checklist = checklist;
    if (clearNotebookId) {
      this.notebookId = null;
    } else if (notebookId != null) {
      this.notebookId = notebookId;
    }
    if (status != null) this.status = status;
    if (clearRichContent) {
      this.richContent = null;
    } else if (richContent != null) {
      this.richContent = richContent;
    }
    if (contentType != null) this.contentType = contentType;
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
