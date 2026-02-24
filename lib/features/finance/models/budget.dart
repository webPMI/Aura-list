import 'package:hive/hive.dart';
import 'finance_enums.dart';

part 'budget.g.dart';

@HiveType(typeId: 18)
class Budget extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String categoryId;

  @HiveField(3)
  late double limit;

  @HiveField(4)
  late BudgetPeriod period;

  @HiveField(5)
  late DateTime startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  late double alertThreshold; // 0.0 - 1.0 (ej: 0.8 = alerta al 80%)

  @HiveField(8)
  late bool rollover;

  @HiveField(9)
  late double rolloverAmount;

  @HiveField(10)
  late bool active;

  @HiveField(11)
  late DateTime createdAt;

  @HiveField(12)
  DateTime? lastUpdatedAt;

  @HiveField(13, defaultValue: false)
  bool deleted;

  @HiveField(14)
  DateTime? deletedAt;

  @HiveField(15)
  String? firestoreId;

  @HiveField(16)
  String? note;

  Budget({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.limit,
    required this.period,
    required this.startDate,
    this.endDate,
    this.alertThreshold = 0.8,
    this.rollover = false,
    this.rolloverAmount = 0.0,
    this.active = true,
    required this.createdAt,
    this.lastUpdatedAt,
    this.deleted = false,
    this.deletedAt,
    this.firestoreId,
    this.note,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'limit': limit,
      'period': period.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'alertThreshold': alertThreshold,
      'rollover': rollover,
      'rolloverAmount': rolloverAmount,
      'active': active,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory Budget.fromFirestore(String id, Map<String, dynamic> data) {
    return Budget(
      id: data['id'] ?? id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      limit: (data['limit'] ?? 0.0).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == data['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(data['startDate'] ?? 0),
      endDate: data['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
          : null,
      alertThreshold: (data['alertThreshold'] ?? 0.8).toDouble(),
      rollover: data['rollover'] ?? false,
      rolloverAmount: (data['rolloverAmount'] ?? 0.0).toDouble(),
      active: data['active'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdatedAt'])
          : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
      firestoreId: id,
      note: data['note'],
    );
  }

  Budget copyWith({
    String? name,
    String? categoryId,
    double? limit,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? alertThreshold,
    bool? rollover,
    double? rolloverAmount,
    bool? active,
    DateTime? lastUpdatedAt,
    bool? deleted,
    DateTime? deletedAt,
    String? note,
  }) {
    return Budget(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      rollover: rollover ?? this.rollover,
      rolloverAmount: rolloverAmount ?? this.rolloverAmount,
      active: active ?? this.active,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      firestoreId: firestoreId,
      note: note ?? this.note,
    );
  }

  bool get isGlobal => categoryId.isEmpty;

  DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(now.year, now.month, now.day);
      case BudgetPeriod.weekly:
        final weekday = now.weekday;
        return DateTime(now.year, now.month, now.day - (weekday - 1));
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.quarterly:
        final quarter = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarter, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime getCurrentPeriodEnd() {
    final start = getCurrentPeriodStart();
    switch (period) {
      case BudgetPeriod.daily:
        return DateTime(start.year, start.month, start.day, 23, 59, 59);
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(start.year, start.month + 1, 1).subtract(const Duration(days: 1));
      case BudgetPeriod.quarterly:
        return DateTime(start.year, start.month + 3, 1).subtract(const Duration(days: 1));
      case BudgetPeriod.yearly:
        return DateTime(start.year + 1, 1, 1).subtract(const Duration(days: 1));
    }
  }
}
