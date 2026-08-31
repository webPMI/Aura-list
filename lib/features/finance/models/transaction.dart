import 'package:hive/hive.dart';
import 'finance_category.dart';

part 'transaction.g.dart';

@HiveType(typeId: 16)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  String? categoryId;

  @HiveField(5)
  late FinanceCategoryType type;

  @HiveField(6)
  String? note;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  DateTime? lastUpdatedAt;

  @HiveField(9, defaultValue: false)
  bool deleted;

  @HiveField(10)
  DateTime? deletedAt;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    required this.type,
    this.note,
    required this.createdAt,
    this.lastUpdatedAt,
    this.deleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'categoryId': categoryId,
      'type': type.name,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromFirestore(String id, Map<String, dynamic> data) {
    return Transaction(
      id: data['id'] ?? id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      categoryId: data['categoryId'] ?? '',
      type: FinanceCategoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FinanceCategoryType.expense,
      ),
      note: data['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdatedAt'])
          : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
    );
  }

  bool get isIncome => type == FinanceCategoryType.income;
  bool get isExpense => type == FinanceCategoryType.expense;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    FinanceCategoryType? type,
    String? note,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    bool? deleted,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}



