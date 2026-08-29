import 'package:hive/hive.dart';

part 'savings_account.g.dart';

/// Tipo de cuenta de ahorro o inversión.
@HiveType(typeId: 31)
enum SavingsAccountType {
  /// Cuenta de ahorro tradicional, perfil conservador.
  @HiveField(0)
  savings,

  /// Cuenta de inversión, rendimiento potencialmente mayor.
  @HiveField(1)
  investment,
}

extension SavingsAccountTypeExtension on SavingsAccountType {
  String get label {
    switch (this) {
      case SavingsAccountType.savings:
        return 'Ahorro';
      case SavingsAccountType.investment:
        return 'Inversión';
    }
  }

  String get iconName {
    switch (this) {
      case SavingsAccountType.savings:
        return 'savings';
      case SavingsAccountType.investment:
        return 'trending_up';
    }
  }

  String get colorHex {
    switch (this) {
      case SavingsAccountType.savings:
        return '#66BB6A';
      case SavingsAccountType.investment:
        return '#2196F3';
    }
  }

  String get description {
    switch (this) {
      case SavingsAccountType.savings:
        return 'Cuenta de ahorro con rendimiento conservador';
      case SavingsAccountType.investment:
        return 'Portafolio de inversión con rendimiento potencial mayor';
    }
  }
}

/// Cuenta de ahorro o inversión gestionada por el usuario.
///
/// Almacena los datos de partida (saldo, aportación mensual, tasa de interés)
/// que alimentan el servicio de simulación `SavingsSimulationService` para
/// proyectar el crecimiento de la cuenta en el tiempo.
@HiveType(typeId: 32)
class SavingsAccount extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late SavingsAccountType type;

  /// Saldo con el que se abrió la cuenta.
  @HiveField(3)
  late double initialBalance;

  /// Saldo actual de la cuenta.
  @HiveField(4)
  late double currentBalance;

  /// Aportación periódica mensual (constante en la simulación).
  @HiveField(5)
  late double monthlyContribution;

  /// Tasa de interés anual en porcentaje (ej: 4.5 = 4.5% anual).
  @HiveField(6)
  late double annualInterestRate;

  @HiveField(7)
  late String icon;

  @HiveField(8)
  late String color; // Color hex string

  /// Fecha de inicio de la cuenta.
  @HiveField(9)
  late DateTime startDate;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  DateTime? lastUpdatedAt;

  @HiveField(12, defaultValue: false)
  bool deleted;

  @HiveField(13)
  DateTime? deletedAt;

  @HiveField(14)
  String? firestoreId;

  SavingsAccount({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.monthlyContribution = 0.0,
    this.annualInterestRate = 0.0,
    String? icon,
    String? color,
    DateTime? startDate,
    required this.createdAt,
    this.lastUpdatedAt,
    this.deleted = false,
    this.deletedAt,
    this.firestoreId,
  }) : icon = icon ?? type.iconName,
       color = color ?? type.colorHex,
       startDate = startDate ?? DateTime.now();

  /// Diferencia entre el saldo actual y el inicial.
  double get gainedAmount => currentBalance - initialBalance;

  /// Retorno total de la cuenta en el presente, expresado en porcentaje.
  double get totalReturnPercentage =>
      initialBalance <= 0 ? 0.0 : (gainedAmount / initialBalance) * 100;

  double get interestEarned => currentBalance - initialBalance;

  SavingsAccount copyWith({
    String? name,
    SavingsAccountType? type,
    double? initialBalance,
    double? currentBalance,
    double? monthlyContribution,
    double? annualInterestRate,
    String? icon,
    String? color,
    DateTime? startDate,
    DateTime? lastUpdatedAt,
    bool? deleted,
    DateTime? deletedAt,
    String? firestoreId,
  }) {
    return SavingsAccount(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'monthlyContribution': monthlyContribution,
      'annualInterestRate': annualInterestRate,
      'icon': icon,
      'color': color,
      'startDate': startDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory SavingsAccount.fromFirestore(String id, Map<String, dynamic> data) {
    return SavingsAccount(
      id: data['id'] ?? id,
      name: data['name'] ?? '',
      type: SavingsAccountType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SavingsAccountType.savings,
      ),
      initialBalance: (data['initialBalance'] ?? 0.0).toDouble(),
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      monthlyContribution: (data['monthlyContribution'] ?? 0.0).toDouble(),
      annualInterestRate: (data['annualInterestRate'] ?? 0.0).toDouble(),
      icon: data['icon'] ?? '',
      color: data['color'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(
        data['startDate'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      lastUpdatedAt: data['lastUpdatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastUpdatedAt'])
          : null,
      deleted: data['deleted'] ?? false,
      deletedAt: data['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedAt'])
          : null,
      firestoreId: id,
    );
  }
}
