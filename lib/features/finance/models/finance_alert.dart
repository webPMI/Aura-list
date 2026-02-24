import 'package:hive/hive.dart';
import 'finance_enums.dart';

part 'finance_alert.g.dart';

@HiveType(typeId: 20)
class FinanceAlert extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late AlertType type;

  @HiveField(2)
  late AlertSeverity severity;

  @HiveField(3)
  late String title;

  @HiveField(4)
  late String message;

  @HiveField(5)
  String? relatedBudgetId;

  @HiveField(6)
  String? relatedCategoryId;

  @HiveField(7)
  String? relatedRecurringTransactionId;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late bool isRead;

  @HiveField(10)
  late bool isDismissed;

  @HiveField(11)
  DateTime? readAt;

  @HiveField(12)
  DateTime? dismissedAt;

  @HiveField(13)
  Map<String, dynamic>? metadata; // Datos adicionales específicos del tipo de alerta

  @HiveField(14, defaultValue: false)
  bool deleted;

  @HiveField(15)
  DateTime? deletedAt;

  FinanceAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.relatedBudgetId,
    this.relatedCategoryId,
    this.relatedRecurringTransactionId,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
    this.readAt,
    this.dismissedAt,
    this.metadata,
    this.deleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'relatedBudgetId': relatedBudgetId,
      'relatedCategoryId': relatedCategoryId,
      'relatedRecurringTransactionId': relatedRecurringTransactionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'isDismissed': isDismissed,
      'readAt': readAt?.millisecondsSinceEpoch,
      'dismissedAt': dismissedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory FinanceAlert.fromFirestore(String id, Map<String, dynamic> data) {
    return FinanceAlert(
      id: data['id'] ?? id,
      type: AlertType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AlertType.budgetWarning,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => AlertSeverity.info,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      relatedBudgetId: data['relatedBudgetId'],
      relatedCategoryId: data['relatedCategoryId'],
      relatedRecurringTransactionId: data['relatedRecurringTransactionId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      isRead: data['isRead'] ?? false,
      isDismissed: data['isDismissed'] ?? false,
      readAt: data['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['readAt'])
          : null,
      dismissedAt: data['dismissedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dismissedAt'])
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
    );
  }

  FinanceAlert copyWith({
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? relatedBudgetId,
    String? relatedCategoryId,
    String? relatedRecurringTransactionId,
    bool? isRead,
    bool? isDismissed,
    DateTime? readAt,
    DateTime? dismissedAt,
    Map<String, dynamic>? metadata,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return FinanceAlert(
      id: id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedBudgetId: relatedBudgetId ?? this.relatedBudgetId,
      relatedCategoryId: relatedCategoryId ?? this.relatedCategoryId,
      relatedRecurringTransactionId: relatedRecurringTransactionId ?? this.relatedRecurringTransactionId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      metadata: metadata ?? this.metadata,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isActive => !isDismissed && !deleted;
}
