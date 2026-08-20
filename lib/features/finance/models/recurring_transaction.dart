import 'package:hive/hive.dart';
import 'package:checklist_app/models/recurrence_rule.dart';
import 'finance_category.dart';

part 'recurring_transaction.g.dart';

/// Modo de pago de una cuota
enum InstallmentPaymentMode {
  /// El sistema genera la transacción automáticamente al llegar la fecha
  automatic,
  /// El usuario confirma manualmente el pago
  manual,
}

/// Estado de una cuota individual
enum InstallmentStatus {
  pending,   // Pendiente de pago
  paid,      // Pagada
  deferred,  // Aplazada (se pospuso al siguiente periodo)
  skipped,   // Omitida (no se pagará)
}

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
  String? categoryId;

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

  /// Número total de cuotas (null = indefinido)
  @HiveField(16)
  int? totalInstallments;

  /// Número de cuotas ya registradas/pagadas
  @HiveField(17, defaultValue: 0)
  int paidInstallments;

  /// Número de cuotas aplazadas (no pagadas a tiempo)
  @HiveField(18, defaultValue: 0)
  int deferredInstallments;

  /// Modo de pago de cuotas (auto o manual)
  @HiveField(19)
  String installmentPaymentModeStr;

  /// Historial de fechas de pago efectivo (serializado como lista de milisegundos)
  @HiveField(20)
  List<int> paymentDateHistory;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    this.categoryId,
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
    this.totalInstallments,
    this.paidInstallments = 0,
    this.deferredInstallments = 0,
    this.installmentPaymentModeStr = 'automatic',
    List<int>? paymentDateHistory,
  }) : paymentDateHistory = paymentDateHistory ?? [];

  /// Calcula la proxima ocurrencia de esta transaccion recurrente.
  /// Retorna null si no hay mas ocurrencias o si esta inactiva.
  DateTime? nextOccurrence() {
    if (!active || deleted) return null;

    final from = lastGenerated != null
        ? lastGenerated!.add(const Duration(days: 1))
        : recurrence.startDate;
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

  // ─────────────── CUOTAS / INSTALLMENTS ───────────────

  /// Si tiene un número fijo de cuotas (no es indefinida).
  bool get hasFixedInstallments => totalInstallments != null;

  /// Si se han completado todas las cuotas.
  bool get isCompleted =>
      hasFixedInstallments && paidInstallments >= totalInstallments!;

  /// Cuotas pendientes de pago.
  int? get remainingInstallments => hasFixedInstallments
      ? (totalInstallments! - paidInstallments).clamp(0, totalInstallments!)
      : null;

  /// Monto total del compromiso (si tiene cuotas fijas).
  double? get totalAmount =>
      hasFixedInstallments ? totalInstallments! * amount : null;

  /// Monto total que queda por pagar.
  double? get remainingAmount =>
      remainingInstallments != null ? remainingInstallments! * amount : null;

  /// Monto ya pagado.
  double get paidAmount => paidInstallments * amount;

  /// Progreso de pago (0.0 a 1.0).
  double get installmentProgress => hasFixedInstallments && totalInstallments! > 0
      ? (paidInstallments / totalInstallments!).clamp(0.0, 1.0)
      : 0.0;

  /// Modo de pago como enum.
  InstallmentPaymentMode get paymentMode =>
      installmentPaymentModeStr == 'manual'
          ? InstallmentPaymentMode.manual
          : InstallmentPaymentMode.automatic;

  /// Fecha estimada de finalización calculada dinámicamente.
  DateTime? get expectedEndDate {
    if (!hasFixedInstallments) return null;
    final remaining = remainingInstallments!;
    if (remaining <= 0) return lastGenerated ?? recurrence.startDate;

    DateTime cursor;
    int steps;
    if (lastGenerated != null) {
      cursor = lastGenerated!;
      steps = remaining;
    } else {
      cursor = recurrence.startDate;
      steps = remaining - 1;
    }

    for (int i = 0; i < steps; i++) {
      final next = recurrence.nextOccurrence(cursor.add(const Duration(days: 1)));
      if (next == null) break;
      cursor = next;
    }
    return cursor;
  }

  /// Descripción compacta del estado de cuotas.
  String get installmentSummary {
    if (!hasFixedInstallments) return 'Indefinido';
    if (isCompleted) return '✅ Completado ($totalInstallments cuotas)';
    return 'Cuota ${paidInstallments + 1} de $totalInstallments';
  }

  /// Lista de fechas de pago como DateTime.
  List<DateTime> get paymentDates =>
      paymentDateHistory.map((ms) => DateTime.fromMillisecondsSinceEpoch(ms)).toList();

  /// Si tiene cuotas con modo manual y hay cuotas pendientes hoy o vencidas.
  bool get hasPendingManualPayment {
    if (!hasFixedInstallments || isCompleted) return false;
    if (paymentMode != InstallmentPaymentMode.manual) return false;
    final next = nextOccurrence();
    if (next == null) return false;
    return DateTime.now().isAfter(next) || _isSameDay(DateTime.now(), next);
  }

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
    Object? totalInstallments = _sentinel,
    int? paidInstallments,
    int? deferredInstallments,
    String? installmentPaymentModeStr,
    List<int>? paymentDateHistory,
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
      totalInstallments: identical(totalInstallments, _sentinel)
          ? this.totalInstallments
          : totalInstallments as int?,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      deferredInstallments: deferredInstallments ?? this.deferredInstallments,
      installmentPaymentModeStr:
          installmentPaymentModeStr ?? this.installmentPaymentModeStr,
      paymentDateHistory: paymentDateHistory ?? List.from(this.paymentDateHistory),
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
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'deferredInstallments': deferredInstallments,
      'installmentPaymentModeStr': installmentPaymentModeStr,
      'paymentDateHistory': paymentDateHistory,
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
      totalInstallments: data['totalInstallments'] as int?,
      paidInstallments: (data['paidInstallments'] ?? 0) as int,
      deferredInstallments: (data['deferredInstallments'] ?? 0) as int,
      installmentPaymentModeStr:
          (data['installmentPaymentModeStr'] ?? 'automatic') as String,
      paymentDateHistory: (data['paymentDateHistory'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
    );
  }

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, title: $title, amount: $amount, '
        'type: $type, active: $active, recurrence: ${recurrence.toDisplayString()}, '
        'installments: $installmentSummary)';
  }
}

// Sentinel para distinguir null explícito de "no pasado" en copyWith
const _sentinel = Object();
