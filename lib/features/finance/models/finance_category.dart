import 'package:hive/hive.dart';

part 'finance_category.g.dart';

@HiveType(typeId: 14)
enum FinanceCategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 15)
class FinanceCategory extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String icon; // Icon name from Material Icons

  @HiveField(3)
  late String color; // Hex color string

  @HiveField(4)
  late FinanceCategoryType type;

  @HiveField(5)
  late bool isDefault;

  FinanceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  factory FinanceCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return FinanceCategory(
      id: data['id'] ?? id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? '#9E9E9E',
      type: FinanceCategoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FinanceCategoryType.expense,
      ),
      isDefault: data['isDefault'] ?? false,
    );
  }

  static List<FinanceCategory> get defaultCategories => [
    // Expenses
    FinanceCategory(
      id: 'exp_food',
      name: 'Alimentación',
      icon: 'restaurant',
      color: '#FF7043',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'exp_transport',
      name: 'Transporte',
      icon: 'directions_car',
      color: '#42A5F5',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'exp_home',
      name: 'Vivienda',
      icon: 'home',
      color: '#66BB6A',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'exp_entertainment',
      name: 'Entretenimiento',
      icon: 'movie',
      color: '#AB47BC',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'exp_health',
      name: 'Salud',
      icon: 'medical_services',
      color: '#EF5350',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'exp_shopping',
      name: 'Compras',
      icon: 'shopping_bag',
      color: '#FFA726',
      type: FinanceCategoryType.expense,
      isDefault: true,
    ),
    // Incomes
    FinanceCategory(
      id: 'inc_salary',
      name: 'Salario',
      icon: 'payments',
      color: '#4CAF50',
      type: FinanceCategoryType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'inc_investments',
      name: 'Inversiones',
      icon: 'trending_up',
      color: '#2196F3',
      type: FinanceCategoryType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'inc_gift',
      name: 'Regalo',
      icon: 'redeem',
      color: '#E91E63',
      type: FinanceCategoryType.income,
      isDefault: true,
    ),
    FinanceCategory(
      id: 'inc_other',
      name: 'Otros Ingresos',
      icon: 'add_circle',
      color: '#9E9E9E',
      type: FinanceCategoryType.income,
      isDefault: true,
    ),
  ];
}
