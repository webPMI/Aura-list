import 'package:hive/hive.dart';
import 'task_model.dart';

part 'task_template.g.dart';

@HiveType(typeId: 30)
class TaskTemplate extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // Template name

  @HiveField(2)
  late String description;

  @HiveField(3)
  late String taskType;

  @HiveField(4)
  late String title; // Task title

  @HiveField(5)
  late String category;

  @HiveField(6)
  late int priority;

  @HiveField(7)
  String? motivation;

  @HiveField(8)
  String? reward;

  @HiveField(9)
  int? dueTimeMinutes;

  @HiveField(10)
  int? daysOffset; // For once tasks

  @HiveField(11)
  int? recurrenceDay;

  @HiveField(12)
  double? financialCost;

  @HiveField(13)
  double? financialBenefit;

  @HiveField(14)
  String? financialCategoryId;

  @HiveField(15)
  String? financialNote;

  @HiveField(16)
  late bool autoGenerateTransaction;

  @HiveField(17)
  String? linkedRecurringTransactionId;

  @HiveField(18)
  late DateTime createdAt;

  @HiveField(19)
  DateTime? lastUsedAt;

  @HiveField(20)
  late int usageCount;

  @HiveField(21)
  late String firestoreId;

  @HiveField(22)
  DateTime? lastUpdatedAt;

  @HiveField(23, defaultValue: false)
  late bool isPinned;

  @HiveField(24)
  List<String>? tags;

  TaskTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.taskType,
    required this.title,
    this.category = 'Personal',
    this.priority = 1,
    this.motivation,
    this.reward,
    this.dueTimeMinutes,
    this.daysOffset,
    this.recurrenceDay,
    this.financialCost,
    this.financialBenefit,
    this.financialCategoryId,
    this.financialNote,
    this.autoGenerateTransaction = false,
    this.linkedRecurringTransactionId,
    DateTime? createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
    this.firestoreId = '',
    this.lastUpdatedAt,
    this.isPinned = false,
    this.tags,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a template from an existing task
  factory TaskTemplate.fromTask({
    required String id,
    required String name,
    required String description,
    required Task task,
    int? daysOffset,
    List<String>? tags,
  }) {
    return TaskTemplate(
      id: id,
      name: name,
      description: description,
      taskType: task.type,
      title: task.title,
      category: task.category,
      priority: task.priority,
      motivation: task.motivation,
      reward: task.reward,
      dueTimeMinutes: task.dueTimeMinutes,
      daysOffset: daysOffset,
      recurrenceDay: task.recurrenceDay,
      financialCost: task.financialCost,
      financialBenefit: task.financialBenefit,
      financialCategoryId: task.financialCategoryId,
      financialNote: task.financialNote,
      autoGenerateTransaction: task.autoGenerateTransaction,
      linkedRecurringTransactionId: task.linkedRecurringTransactionId,
      tags: tags,
    );
  }

  /// Convert template to a task with current date adjustments
  Task toTask() {
    final now = DateTime.now();
    DateTime? dueDate;

    // Calculate due date based on task type and offset
    if (taskType == 'once' && daysOffset != null) {
      dueDate = now.add(Duration(days: daysOffset!));
    } else if (taskType == 'weekly' || taskType == 'monthly') {
      // For recurring tasks, set due date to today
      dueDate = now;
    }

    return Task(
      title: title,
      type: taskType,
      isCompleted: false,
      createdAt: now,
      dueDate: dueDate,
      category: category,
      priority: priority,
      dueTimeMinutes: dueTimeMinutes,
      motivation: motivation,
      reward: reward,
      recurrenceDay: recurrenceDay,
      financialCost: financialCost,
      financialBenefit: financialBenefit,
      financialCategoryId: financialCategoryId,
      financialNote: financialNote,
      autoGenerateTransaction: autoGenerateTransaction,
      linkedRecurringTransactionId: linkedRecurringTransactionId,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'taskType': taskType,
      'title': title,
      'category': category,
      'priority': priority,
      'motivation': motivation,
      'reward': reward,
      'dueTimeMinutes': dueTimeMinutes,
      'daysOffset': daysOffset,
      'recurrenceDay': recurrenceDay,
      'financialCost': financialCost,
      'financialBenefit': financialBenefit,
      'financialCategoryId': financialCategoryId,
      'financialNote': financialNote,
      'autoGenerateTransaction': autoGenerateTransaction,
      'linkedRecurringTransactionId': linkedRecurringTransactionId,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      'isPinned': isPinned,
      'tags': tags,
    };
  }

  /// Create from Firestore document
  factory TaskTemplate.fromFirestore(String firestoreId, Map<String, dynamic> data) {
    return TaskTemplate(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      taskType: data['taskType'] ?? 'daily',
      title: data['title'] ?? '',
      category: data['category'] ?? 'Personal',
      priority: data['priority'] ?? 1,
      motivation: data['motivation'],
      reward: data['reward'],
      dueTimeMinutes: data['dueTimeMinutes'],
      daysOffset: data['daysOffset'],
      recurrenceDay: data['recurrenceDay'],
      financialCost: data['financialCost']?.toDouble(),
      financialBenefit: data['financialBenefit']?.toDouble(),
      financialCategoryId: data['financialCategoryId'],
      financialNote: data['financialNote'],
      autoGenerateTransaction: data['autoGenerateTransaction'] ?? false,
      linkedRecurringTransactionId: data['linkedRecurringTransactionId'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastUsedAt: data['lastUsedAt'] != null
          ? DateTime.parse(data['lastUsedAt'])
          : null,
      usageCount: data['usageCount'] ?? 0,
      firestoreId: firestoreId,
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.parse(data['lastUpdatedAt'])
          : null,
      isPinned: data['isPinned'] ?? false,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
    );
  }

  /// Create a copy with updated fields
  TaskTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? taskType,
    String? title,
    String? category,
    int? priority,
    String? motivation,
    String? reward,
    int? dueTimeMinutes,
    int? daysOffset,
    int? recurrenceDay,
    double? financialCost,
    double? financialBenefit,
    String? financialCategoryId,
    String? financialNote,
    bool? autoGenerateTransaction,
    String? linkedRecurringTransactionId,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? usageCount,
    String? firestoreId,
    DateTime? lastUpdatedAt,
    bool? isPinned,
    List<String>? tags,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      motivation: motivation ?? this.motivation,
      reward: reward ?? this.reward,
      dueTimeMinutes: dueTimeMinutes ?? this.dueTimeMinutes,
      daysOffset: daysOffset ?? this.daysOffset,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      financialCost: financialCost ?? this.financialCost,
      financialBenefit: financialBenefit ?? this.financialBenefit,
      financialCategoryId: financialCategoryId ?? this.financialCategoryId,
      financialNote: financialNote ?? this.financialNote,
      autoGenerateTransaction: autoGenerateTransaction ?? this.autoGenerateTransaction,
      linkedRecurringTransactionId: linkedRecurringTransactionId ?? this.linkedRecurringTransactionId,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
      firestoreId: firestoreId ?? this.firestoreId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
    );
  }

  /// Mark template as used (increment counter and update timestamp)
  void markAsUsed() {
    usageCount++;
    lastUsedAt = DateTime.now();
    lastUpdatedAt = DateTime.now();
  }

  /// Get type label in Spanish
  String get typeLabel {
    switch (taskType) {
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

  /// Check if template matches search query
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        title.toLowerCase().contains(lowerQuery) ||
        category.toLowerCase().contains(lowerQuery) ||
        (tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false);
  }
}
