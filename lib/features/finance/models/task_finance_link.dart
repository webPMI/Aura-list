import 'package:hive/hive.dart';

part 'task_finance_link.g.dart';

@HiveType(typeId: 28)
enum FinancialImpactType {
  @HiveField(0)
  cost, // La tarea genera un gasto
  @HiveField(1)
  saving, // La tarea genera un ahorro
  @HiveField(2)
  income, // La tarea genera un ingreso
}

@HiveType(typeId: 29)
class TaskFinanceLink extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String taskId;

  @HiveField(2)
  late FinancialImpactType impactType;

  @HiveField(3)
  late double estimatedAmount;

  @HiveField(4)
  String? actualTransactionId; // ID de transacción real creada

  @HiveField(5)
  late String categoryId;

  @HiveField(6)
  String? note;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  DateTime? linkedAt; // Cuando se vinculó a una transacción real

  @HiveField(9, defaultValue: false)
  bool deleted;

  @HiveField(10)
  DateTime? deletedAt;

  @HiveField(11)
  late bool autoCreateTransaction; // Crear automáticamente transacción al completar tarea

  TaskFinanceLink({
    required this.id,
    required this.taskId,
    required this.impactType,
    required this.estimatedAmount,
    this.actualTransactionId,
    required this.categoryId,
    this.note,
    required this.createdAt,
    this.linkedAt,
    this.deleted = false,
    this.deletedAt,
    this.autoCreateTransaction = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'taskId': taskId,
      'impactType': impactType.name,
      'estimatedAmount': estimatedAmount,
      'actualTransactionId': actualTransactionId,
      'categoryId': categoryId,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'linkedAt': linkedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'autoCreateTransaction': autoCreateTransaction,
    };
  }

  factory TaskFinanceLink.fromFirestore(String id, Map<String, dynamic> data) {
    return TaskFinanceLink(
      id: data['id'] ?? id,
      taskId: data['taskId'] ?? '',
      impactType: FinancialImpactType.values.firstWhere(
        (e) => e.name == data['impactType'],
        orElse: () => FinancialImpactType.cost,
      ),
      estimatedAmount: (data['estimatedAmount'] ?? 0.0).toDouble(),
      actualTransactionId: data['actualTransactionId'],
      categoryId: data['categoryId'] ?? '',
      note: data['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      linkedAt: data['linkedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['linkedAt'])
          : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
      autoCreateTransaction: data['autoCreateTransaction'] ?? false,
    );
  }

  TaskFinanceLink copyWith({
    String? taskId,
    FinancialImpactType? impactType,
    double? estimatedAmount,
    String? actualTransactionId,
    String? categoryId,
    String? note,
    DateTime? linkedAt,
    bool? deleted,
    DateTime? deletedAt,
    bool? autoCreateTransaction,
  }) {
    return TaskFinanceLink(
      id: id,
      taskId: taskId ?? this.taskId,
      impactType: impactType ?? this.impactType,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      actualTransactionId: actualTransactionId ?? this.actualTransactionId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      createdAt: createdAt,
      linkedAt: linkedAt ?? this.linkedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      autoCreateTransaction: autoCreateTransaction ?? this.autoCreateTransaction,
    );
  }

  bool get isLinked => actualTransactionId != null;
}
