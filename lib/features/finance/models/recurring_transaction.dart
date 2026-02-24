import 'package:hive/hive.dart';
import 'package:checklist_app/models/recurrence_rule.dart';
import 'finance_category.dart';

part 'recurring_transaction.g.dart';

/// Transaccion recurrente que se genera automaticamente segun una regla de recurrencia.
@HiveType(typeId: 17)
class RecurringTransaction extends HiveObject {
  /// Identificador unico
  @HiveField(0)
  late String id;

  /// Titulo de la transaccion recurrente
  @HiveField(1)
  late String title;

  /// Monto de la transaccion
  @HiveField(2)
  late double amount;

  /// ID de la categoria de finanzas
  @HiveField(3)
  late String categoryId;

  /// Tipo de transaccion (ingreso o gasto)
  @HiveField(4)
  late FinanceCategoryType type;

  /// Regla de recurrencia
  @HiveField(5)
  late RecurrenceRule recurrence;

  /// Si se debe generar automaticamente la transaccion
  @HiveField(6)
  late bool autoGenerate;

  /// Fecha de la ultima transaccion generada
  @HiveField(7)
  DateTime? lastGenerated;

  /// Si la transaccion recurrente esta activa
  @HiveField(8)
  late bool active;

  /// ID de tarea vinculada (opcional)
  @HiveField(9)
  String? linkedTaskId;

  /// Notas adicionales
  @HiveField(10)
  String? note;

  /// Fecha de creacion
  @HiveField(11)
  late DateTime createdAt;

  /// Fecha de ultima actualizacion
  @HiveField(12)
  DateTime? lastUpdatedAt;

  /// Soft delete flag
  @HiveField(13, defaultValue: false)
  bool deleted;

  /// Timestamp de borrado
  @HiveField(14)
  DateTime? deletedAt;

  /// ID de documento en Firestore (opcional)
  @HiveField(15)
  String? firestoreId;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.recurrence,
    this.autoGenerate = true,
    this.lastGenerated,
    this.active = true,
    this.linkedTaskId,
    this.note,
    required this.createdAt,
    this.lastUpdatedAt,
    this.deleted = false,
    this.deletedAt,
    this.firestoreId,
  });

  /// Calcula la proxima ocurrencia de esta transaccion recurrente.
  /// Retorna null si no hay mas ocurrencias o si esta inactiva.
  DateTime? nextOccurrence() {
    if (!active || deleted) return null;

    final from = lastGenerated ?? recurrence.startDate;
    return recurrence.nextOccurrence(from);
  }

  /// Verifica si esta lista para generar una nueva transaccion.
  bool get isPendingGeneration {
    if (!active || !autoGenerate || deleted) return false;

    final next = nextOccurrence();
    if (next == null) return false;

    // Verificar si la fecha de la proxima ocurrencia ya paso
    return DateTime.now().isAfter(next) || _isSameDay(DateTime.now(), next);
  }

  /// Verifica si dos fechas son el mismo dia.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Obtiene una descripcion legible de la recurrencia.
  String get recurrenceDescription => recurrence.toDisplayString();

  /// Verifica si es un ingreso.
  bool get isIncome => type == FinanceCategoryType.income;

  /// Verifica si es un gasto.
  bool get isExpense => type == FinanceCategoryType.expense;

  /// Verifica si la transaccion recurrente esta activa.
  bool get isActive => active && !deleted;

  /// Obtiene la frecuencia de la recurrencia.
  String get frequency => recurrence.frequency.name;

  /// Copia con campos modificados.
  RecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? categoryId,
    FinanceCategoryType? type,
    RecurrenceRule? recurrence,
    bool? autoGenerate,
    DateTime? lastGenerated,
    bool clearLastGenerated = false,
    bool? active,
    String? linkedTaskId,
    bool clearLinkedTaskId = false,
    String? note,
    bool clearNote = false,
    DateTime? lastUpdatedAt,
    bool? deleted,
    DateTime? deletedAt,
    String? firestoreId,
    bool clearFirestoreId = false,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      recurrence: recurrence ?? this.recurrence,
      autoGenerate: autoGenerate ?? this.autoGenerate,
      lastGenerated: clearLastGenerated ? null : (lastGenerated ?? this.lastGenerated),
      active: active ?? this.active,
      linkedTaskId: clearLinkedTaskId ? null : (linkedTaskId ?? this.linkedTaskId),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      firestoreId: clearFirestoreId ? null : (firestoreId ?? this.firestoreId),
    );
  }

  /// Convierte a Map para Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'type': type.name,
      'recurrence': recurrence.toJson(),
      'autoGenerate': autoGenerate,
      'lastGenerated': lastGenerated?.millisecondsSinceEpoch,
      'active': active,
      'linkedTaskId': linkedTaskId,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
      'deleted': deleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  /// Crea desde Map de Firestore.
  factory RecurringTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    return RecurringTransaction(
      id: data['id'] ?? id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      type: FinanceCategoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => FinanceCategoryType.expense,
      ),
      recurrence: RecurrenceRule.fromJson(data['recurrence'] as Map<String, dynamic>),
      autoGenerate: data['autoGenerate'] ?? true,
      lastGenerated: data['lastGenerated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastGenerated'])
          : null,
      active: data['active'] ?? true,
      linkedTaskId: data['linkedTaskId'],
      note: data['note'],
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

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, title: $title, amount: $amount, '
        'type: $type, active: $active, recurrence: ${recurrence.toDisplayString()})';
  }
}
