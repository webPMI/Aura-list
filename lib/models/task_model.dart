import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String firestoreId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type; // 'daily', 'weekly', 'monthly', 'yearly', 'once'

  @HiveField(3)
  late bool isCompleted;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  late String category; // 'Personal', 'Work', 'Home', etc.

  @HiveField(7)
  late int priority; // 0: Low, 1: Medium, 2: High

  @HiveField(8)
  int? dueTimeMinutes; // Minutes since midnight (0-1439)

  @HiveField(9)
  String? motivation; // Mensaje motivador: "¿Por qué quieres lograr esto?"

  @HiveField(10)
  String? reward; // Recompensa al completar: "Me premiaré con..."

  @HiveField(11)
  int? recurrenceDay; // Día de recurrencia (1=Lun, 7=Dom) para weekly, (1-31) para monthly

  @HiveField(12)
  DateTime? deadline; // Fecha límite estricta (diferente a dueDate que es sugerida)

  @HiveField(13, defaultValue: false)
  bool deleted; // Soft delete flag

  @HiveField(14)
  DateTime? deletedAt; // Timestamp de borrado

  @HiveField(15)
  DateTime? lastUpdatedAt; // Para sync incremental

  Task({
    this.firestoreId = '',
    required this.title,
    required this.type,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.category = 'Personal',
    this.priority = 1,
    this.dueTimeMinutes,
    this.motivation,
    this.reward,
    this.recurrenceDay,
    this.deadline,
    this.deleted = false,
    this.deletedAt,
    this.lastUpdatedAt,
  });

  // For compatibility with existing code
  int get id => key ?? 0;

  // Convert dueTimeMinutes to TimeOfDay
  TimeOfDay? get dueTime {
    if (dueTimeMinutes == null) return null;
    final hours = dueTimeMinutes! ~/ 60;
    final minutes = dueTimeMinutes! % 60;
    return TimeOfDay(hour: hours, minute: minutes);
  }

  // Combine dueDate and dueTime into a complete DateTime
  DateTime? get dueDateTimeComplete {
    if (dueDate == null) return null;
    if (dueTimeMinutes == null) return dueDate;

    final hours = dueTimeMinutes! ~/ 60;
    final minutes = dueTimeMinutes! % 60;

    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      hours,
      minutes,
    );
  }

  // Get the label in Spanish for the task type
  String get typeLabel {
    switch (type) {
      case 'daily':
        return 'Diaria';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      case 'once':
        return 'Única';
      default:
        return 'Diaria';
    }
  }

  // Get the icon for the task type
  IconData get typeIcon {
    switch (type) {
      case 'daily':
        return Icons.wb_sunny_outlined;
      case 'weekly':
        return Icons.calendar_view_week_outlined;
      case 'monthly':
        return Icons.calendar_month_outlined;
      case 'yearly':
        return Icons.event_outlined;
      case 'once':
        return Icons.push_pin_outlined;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'dueTimeMinutes': dueTimeMinutes,
      'motivation': motivation,
      'reward': reward,
      'recurrenceDay': recurrenceDay,
      'deadline': deadline?.toIso8601String(),
      'deleted': deleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      firestoreId: id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'daily',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      category: data['category'] ?? 'Personal',
      priority: data['priority'] ?? 1,
      dueTimeMinutes: data['dueTimeMinutes'],
      motivation: data['motivation'],
      reward: data['reward'],
      recurrenceDay: data['recurrenceDay'],
      deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null ? DateTime.parse(data['deletedAt']) : null,
      lastUpdatedAt: data['lastUpdatedAt'] != null ? DateTime.parse(data['lastUpdatedAt']) : null,
    );
  }

  /// Crea una nueva instancia con los campos modificados (inmutable).
  /// Usar este metodo cuando se necesita una copia sin modificar el original.
  Task copyWith({
    String? firestoreId,
    String? title,
    String? type,
    bool? isCompleted,
    DateTime? dueDate,
    String? category,
    int? priority,
    int? dueTimeMinutes,
    bool clearDueTime = false,
    String? motivation,
    String? reward,
    int? recurrenceDay,
    DateTime? deadline,
    bool? deleted,
    DateTime? deletedAt,
    DateTime? lastUpdatedAt,
  }) {
    return Task(
      firestoreId: firestoreId ?? this.firestoreId,
      title: title ?? this.title,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueTimeMinutes: clearDueTime ? null : (dueTimeMinutes ?? this.dueTimeMinutes),
      motivation: motivation ?? this.motivation,
      reward: reward ?? this.reward,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      deadline: deadline ?? this.deadline,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  /// Actualiza los campos in-place cuando el objeto esta en Hive.
  /// Usar este metodo para modificar un objeto que ya esta guardado.
  void updateInPlace({
    String? firestoreId,
    String? title,
    String? type,
    bool? isCompleted,
    DateTime? dueDate,
    String? category,
    int? priority,
    int? dueTimeMinutes,
    bool clearDueTime = false,
    String? motivation,
    String? reward,
    int? recurrenceDay,
    DateTime? deadline,
    bool? deleted,
    DateTime? deletedAt,
    DateTime? lastUpdatedAt,
  }) {
    if (firestoreId != null) this.firestoreId = firestoreId;
    if (title != null) this.title = title;
    if (type != null) this.type = type;
    if (isCompleted != null) this.isCompleted = isCompleted;
    if (dueDate != null) this.dueDate = dueDate;
    if (category != null) this.category = category;
    if (priority != null) this.priority = priority;
    if (clearDueTime) {
      this.dueTimeMinutes = null;
    } else if (dueTimeMinutes != null) {
      this.dueTimeMinutes = dueTimeMinutes;
    }
    if (motivation != null) this.motivation = motivation;
    if (reward != null) this.reward = reward;
    if (recurrenceDay != null) this.recurrenceDay = recurrenceDay;
    if (deadline != null) this.deadline = deadline;
    if (deleted != null) this.deleted = deleted;
    if (deletedAt != null) this.deletedAt = deletedAt;
    if (lastUpdatedAt != null) this.lastUpdatedAt = lastUpdatedAt;
  }

  // Default motivational messages
  static const List<String> defaultMotivations = [
    '¡Tú puedes lograrlo! 💪',
    'Un paso más hacia tu mejor versión ⭐',
    'Cada tarea completada es una victoria 🏆',
    'Tu futuro yo te lo agradecerá 🙏',
    '¡Hoy es un gran día para avanzar! 🚀',
  ];

  // Get motivational text (custom or default)
  String get motivationText {
    if (motivation != null && motivation!.isNotEmpty) return motivation!;
    return defaultMotivations[title.hashCode.abs() % defaultMotivations.length];
  }

  // Check if task is overdue
  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!);
  }

  // Check if task is urgent (within 24 hours)
  bool get isUrgent {
    if (deadline == null) return false;
    final diff = deadline!.difference(DateTime.now());
    return diff.inHours <= 24 && diff.inHours >= 0;
  }
}
