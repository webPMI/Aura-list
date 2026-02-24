import 'package:hive/hive.dart';

part 'cash_flow_projection.g.dart';

@HiveType(typeId: 19)
class CashFlowProjection extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date; // Fecha de la proyección

  @HiveField(2)
  late double projectedIncome;

  @HiveField(3)
  late double projectedExpenses;

  @HiveField(4)
  late double projectedBalance;

  @HiveField(5)
  late double actualIncome; // Ingresos reales hasta la fecha

  @HiveField(6)
  late double actualExpenses; // Gastos reales hasta la fecha

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late DateTime lastUpdatedAt;

  @HiveField(9)
  late bool isHistorical; // true si la fecha ya pasó

  @HiveField(10, defaultValue: false)
  bool deleted;

  @HiveField(11)
  DateTime? deletedAt;

  CashFlowProjection({
    required this.id,
    required this.date,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedBalance,
    this.actualIncome = 0.0,
    this.actualExpenses = 0.0,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isHistorical = false,
    this.deleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'projectedIncome': projectedIncome,
      'projectedExpenses': projectedExpenses,
      'projectedBalance': projectedBalance,
      'actualIncome': actualIncome,
      'actualExpenses': actualExpenses,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': lastUpdatedAt.millisecondsSinceEpoch,
      'isHistorical': isHistorical,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory CashFlowProjection.fromFirestore(String id, Map<String, dynamic> data) {
    return CashFlowProjection(
      id: data['id'] ?? id,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      projectedIncome: (data['projectedIncome'] ?? 0.0).toDouble(),
      projectedExpenses: (data['projectedExpenses'] ?? 0.0).toDouble(),
      projectedBalance: (data['projectedBalance'] ?? 0.0).toDouble(),
      actualIncome: (data['actualIncome'] ?? 0.0).toDouble(),
      actualExpenses: (data['actualExpenses'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(data['lastUpdatedAt'] ?? 0),
      isHistorical: data['isHistorical'] ?? false,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
    );
  }

  CashFlowProjection copyWith({
    DateTime? date,
    double? projectedIncome,
    double? projectedExpenses,
    double? projectedBalance,
    double? actualIncome,
    double? actualExpenses,
    DateTime? lastUpdatedAt,
    bool? isHistorical,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return CashFlowProjection(
      id: id,
      date: date ?? this.date,
      projectedIncome: projectedIncome ?? this.projectedIncome,
      projectedExpenses: projectedExpenses ?? this.projectedExpenses,
      projectedBalance: projectedBalance ?? this.projectedBalance,
      actualIncome: actualIncome ?? this.actualIncome,
      actualExpenses: actualExpenses ?? this.actualExpenses,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isHistorical: isHistorical ?? this.isHistorical,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  double get actualBalance => actualIncome - actualExpenses;
  double get variance => actualBalance - projectedBalance;
  double get incomeVariance => actualIncome - projectedIncome;
  double get expenseVariance => actualExpenses - projectedExpenses;

  double get accuracy {
    if (projectedBalance == 0) return 1.0;
    return 1.0 - (variance.abs() / projectedBalance.abs()).clamp(0.0, 1.0);
  }
}
