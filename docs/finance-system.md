# Sistema de Finanzas de AuraList

## Resumen

El sistema de finanzas de AuraList es una solución completa y offline-first para el manejo de transacciones, presupuestos, transacciones recurrentes y proyecciones de flujo de efectivo. Está completamente integrado con el sistema de tareas, permitiendo vincular el impacto financiero de las tareas con transacciones reales.

## Arquitectura

### Principio Offline-First

Al igual que el resto de AuraList, el sistema de finanzas sigue el patrón offline-first:

```
UI (ConsumerWidget) ← watches ← Riverpod Providers ← streams ← Hive (local)
                                       ↓
                              Firebase Firestore (async sync)
                                       ↓
                              Sync Queue (retry on failure)
```

- **Datos locales primero**: Todas las operaciones se guardan primero en Hive
- **UI reactiva**: Los cambios se reflejan inmediatamente mediante streams
- **Sincronización asíncrona**: Firebase sync ocurre en segundo plano
- **Reintentos automáticos**: Fallos de sincronización se encolan y reintenta con backoff exponencial

### Modelos de Datos

#### Transaction (typeId: 16)

Representa una transacción financiera individual (ingreso o gasto).

```dart
@HiveType(typeId: 16)
class Transaction extends HiveObject {
  String id;              // Identificador único
  String title;           // Título de la transacción
  double amount;          // Monto
  DateTime date;          // Fecha de la transacción
  String categoryId;      // ID de categoría (ej: 'exp_food', 'inc_salary')
  FinanceCategoryType type; // income o expense
  String? note;           // Notas adicionales
  DateTime createdAt;     // Fecha de creación
  DateTime? lastUpdatedAt; // Última actualización
  bool deleted;           // Soft delete
  DateTime? deletedAt;    // Timestamp de borrado
}
```

**Propiedades útiles:**
- `isIncome`: true si es ingreso
- `isExpense`: true si es gasto

#### RecurringTransaction (typeId: 17)

Transacciones que se repiten automáticamente según una regla de recurrencia.

```dart
@HiveType(typeId: 17)
class RecurringTransaction extends HiveObject {
  String id;
  String title;
  double amount;
  String categoryId;
  FinanceCategoryType type;
  RecurrenceRule recurrence;    // Regla de recurrencia (diaria, semanal, mensual, anual)
  bool autoGenerate;            // Si generar automáticamente transacciones
  DateTime? lastGenerated;      // Última vez que se generó
  bool active;                  // Si está activa
  String? linkedTaskId;         // Tarea vinculada (opcional)
  String? note;
  DateTime createdAt;
  DateTime? lastUpdatedAt;
  bool deleted;
  DateTime? deletedAt;
  String? firestoreId;
}
```

**Métodos importantes:**
- `nextOccurrence()`: Calcula la próxima fecha de ocurrencia
- `isPendingGeneration`: true si debe generarse una transacción
- `recurrenceDescription`: Descripción legible de la recurrencia

**Ejemplo de uso:**
```dart
final recurring = RecurringTransaction(
  id: 'recurring_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Salario mensual',
  amount: 3000.0,
  categoryId: 'inc_salary',
  type: FinanceCategoryType.income,
  recurrence: RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    startDate: DateTime.now(),
    dayOfMonth: 1, // Día 1 de cada mes
  ),
  autoGenerate: true,
  active: true,
  createdAt: DateTime.now(),
);
```

#### Budget (typeId: 18)

Límites de gasto por categoría y período.

```dart
@HiveType(typeId: 18)
class Budget extends HiveObject {
  String id;
  String name;              // Nombre del presupuesto
  String categoryId;        // Categoría (vacío = presupuesto global)
  double limit;             // Límite de gasto
  BudgetPeriod period;      // weekly, monthly, quarterly, yearly
  DateTime startDate;       // Fecha de inicio
  DateTime? endDate;        // Fecha de fin (opcional)
  double alertThreshold;    // 0.0-1.0 (ej: 0.8 = alerta al 80%)
  bool rollover;            // Si transferir saldo no gastado al siguiente período
  double rolloverAmount;    // Monto transferido
  bool active;
  DateTime createdAt;
  DateTime? lastUpdatedAt;
  bool deleted;
  DateTime? deletedAt;
  String? firestoreId;
  String? note;
}
```

**Propiedades y métodos:**
- `isGlobal`: true si es presupuesto global (sin categoría)
- `getCurrentPeriodStart()`: Fecha de inicio del período actual
- `getCurrentPeriodEnd()`: Fecha de fin del período actual

**Ejemplo de uso:**
```dart
final budget = Budget(
  id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
  name: 'Presupuesto de Alimentación',
  categoryId: 'exp_food',
  limit: 500.0,
  period: BudgetPeriod.monthly,
  startDate: DateTime(2025, 1, 1),
  alertThreshold: 0.8, // Alerta al 80%
  rollover: true,      // Transferir saldo no gastado
  active: true,
  createdAt: DateTime.now(),
);
```

#### CashFlowProjection (typeId: 19)

Proyecciones de flujo de efectivo para períodos futuros.

```dart
@HiveType(typeId: 19)
class CashFlowProjection extends HiveObject {
  String id;
  DateTime date;              // Fecha de la proyección
  double projectedIncome;     // Ingresos proyectados
  double projectedExpenses;   // Gastos proyectados
  double projectedBalance;    // Balance proyectado
  double actualIncome;        // Ingresos reales (si la fecha ya pasó)
  double actualExpenses;      // Gastos reales
  DateTime createdAt;
  DateTime lastUpdatedAt;
  bool isHistorical;          // true si la fecha ya pasó
  bool deleted;
  DateTime? deletedAt;
}
```

**Propiedades calculadas:**
- `actualBalance`: Balance real (actualIncome - actualExpenses)
- `variance`: Diferencia entre balance real y proyectado
- `incomeVariance`: Diferencia en ingresos
- `expenseVariance`: Diferencia en gastos
- `accuracy`: Precisión de la proyección (0.0-1.0)

#### FinanceAlert (typeId: 20)

Alertas inteligentes sobre presupuestos, gastos inusuales, etc.

```dart
@HiveType(typeId: 20)
class FinanceAlert extends HiveObject {
  String id;
  AlertType type;           // budgetExceeded, budgetWarning, negativeCashFlow, etc.
  AlertSeverity severity;   // info, warning, critical
  String title;
  String message;
  String? relatedBudgetId;
  String? relatedCategoryId;
  String? relatedRecurringTransactionId;
  DateTime createdAt;
  bool isRead;
  bool isDismissed;
  DateTime? readAt;
  DateTime? dismissedAt;
  Map<String, dynamic>? metadata; // Datos adicionales
}
```

**Tipos de alerta (AlertType):**
- `budgetExceeded`: Presupuesto excedido
- `budgetWarning`: Cerca de exceder presupuesto
- `negativeCashFlow`: Flujo de efectivo negativo
- `unusualExpense`: Gasto inusual detectado
- `unusualIncome`: Ingreso inusual detectado
- `recurringTransactionDue`: Transacción recurrente pendiente
- `lowBalance`: Saldo bajo

**Severidad (AlertSeverity):**
- `info`: Informativo, no requiere acción inmediata
- `warning`: Advertencia, requiere atención
- `critical`: Crítico, requiere acción inmediata

#### TaskFinanceLink (typeId: 29)

Vinculación entre tareas y finanzas.

```dart
@HiveType(typeId: 29)
class TaskFinanceLink extends HiveObject {
  String id;
  String taskId;
  FinancialImpactType impactType; // cost, saving, income
  double estimatedAmount;
  String? actualTransactionId;    // Transacción real creada
  String categoryId;
  String? note;
  DateTime createdAt;
  DateTime? linkedAt;
  bool deleted;
  bool autoCreateTransaction;     // Crear transacción al completar tarea
}
```

**Tipos de impacto (FinancialImpactType, typeId: 28):**
- `cost`: La tarea genera un gasto
- `saving`: La tarea genera un ahorro
- `income`: La tarea genera un ingreso

#### FinanceCategory (typeId: 15)

Categorías para clasificar transacciones.

```dart
@HiveType(typeId: 15)
class FinanceCategory extends HiveObject {
  String id;
  String name;
  String icon;              // Nombre del ícono de Material Icons
  String color;             // Color hex (ej: '#FF7043')
  FinanceCategoryType type; // income o expense
  bool isDefault;           // Si es una categoría por defecto
}
```

**Categorías por defecto:**

Gastos:
- `exp_food`: Alimentación (restaurant, #FF7043)
- `exp_transport`: Transporte (directions_car, #42A5F5)
- `exp_home`: Vivienda (home, #66BB6A)
- `exp_entertainment`: Entretenimiento (movie, #AB47BC)
- `exp_health`: Salud (medical_services, #EF5350)
- `exp_shopping`: Compras (shopping_bag, #FFA726)

Ingresos:
- `inc_salary`: Salario (payments, #4CAF50)
- `inc_investments`: Inversiones (trending_up, #2196F3)
- `inc_gift`: Regalo (redeem, #E91E63)
- `inc_other`: Otros Ingresos (add_circle, #9E9E9E)

### TypeIds de Hive Usados

| TypeId | Modelo/Enum |
|--------|-------------|
| 14 | FinanceCategoryType |
| 15 | FinanceCategory |
| 16 | Transaction |
| 17 | RecurringTransaction |
| 18 | Budget |
| 19 | CashFlowProjection |
| 20 | FinanceAlert |
| 22 | RecurrenceFrequency |
| 23 | BudgetPeriod |
| 24 | TaskFinanceLinkType |
| 25 | AlertType |
| 26 | AlertSeverity |
| 27 | RiskLevel |
| 28 | FinancialImpactType |
| 29 | TaskFinanceLink |

### Extensión del Modelo Task

El modelo `Task` (typeId: 0) fue extendido con campos financieros:

```dart
@HiveField(16)
double? financialCost;              // Costo de realizar la tarea

@HiveField(17)
double? financialBenefit;           // Beneficio de completar la tarea

@HiveField(18)
String? linkedTransactionId;        // ID de transacción generada

@HiveField(19)
String? financialImpactType;        // 'immediate', 'deferred', 'recurring'

@HiveField(20, defaultValue: false)
bool autoGenerateTransaction;       // Si crear transacción automáticamente

@HiveField(21)
String? financialCategoryId;        // Categoría financiera a usar

@HiveField(22)
String? linkedRecurringTransactionId; // ID de transacción recurrente

@HiveField(23)
String? financialNote;              // Nota sobre el impacto financiero
```

**Propiedades útiles del Task:**
- `hasFinancialImpact`: true si tiene costo o beneficio
- `netFinancialImpact`: Cálculo neto (beneficio - costo)
- `financialROI`: Return on Investment (si tiene costo y beneficio)

## Servicios

### FinanceProvider

Provider principal para gestionar el estado de finanzas.

```dart
final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  return FinanceNotifier(repository: repository, ref: ref);
});
```

**Estado (FinanceState):**
```dart
class FinanceState {
  List<Transaction> transactions;
  List<FinanceCategory> categories;
  bool isLoading;

  double get totalIncome;      // Suma de todos los ingresos
  double get totalExpenses;    // Suma de todos los gastos
  double get balance;          // Balance neto
}
```

**Métodos disponibles:**
```dart
// Agregar transacción
await ref.read(financeProvider.notifier).addTransaction(
  title: 'Supermercado',
  amount: 75.50,
  date: DateTime.now(),
  categoryId: 'exp_food',
  type: FinanceCategoryType.expense,
  note: 'Compras semanales',
);

// Eliminar transacción
await ref.read(financeProvider.notifier).deleteTransaction(transactionKey);

// Agregar categoría personalizada
await ref.read(financeProvider.notifier).addCategory(
  FinanceCategory(
    id: 'exp_custom_${DateTime.now().millisecondsSinceEpoch}',
    name: 'Mascotas',
    icon: 'pets',
    color: '#FFC107',
    type: FinanceCategoryType.expense,
  ),
);
```

### RecurringTransactionService

Servicio para gestionar transacciones recurrentes y generarlas automáticamente.

```dart
final recurringTransactionService = RecurringTransactionService();

// Detectar patrones de recurrencia en transacciones existentes
final patterns = await recurringTransactionService.detectRecurringPatterns(
  transactions,
  minOccurrences: 3, // Mínimo 3 ocurrencias para considerar patrón
);

// Generar transacciones pendientes
await recurringTransactionService.generatePendingTransactions(
  recurringTransactions,
  userId,
);
```

### TaskFinanceIntegrationService

Servicio de integración entre tareas y finanzas.

```dart
final integrationService = ref.read(taskFinanceIntegrationServiceProvider);

// Al completar una tarea, genera automáticamente transacción si está configurado
final transactionId = await integrationService.onTaskCompleted(task);

// Calcular ROI de una tarea
final roi = integrationService.calculateTaskROI(task);

// Sugerir vinculación con transacciones existentes
final suggestions = await integrationService.suggestFinancialLink(task);

// Obtener estadísticas financieras de tareas
final stats = integrationService.getFinancialTaskStats(allTasks);
// stats contiene:
// - tasksWithFinancialImpact
// - completedWithImpact
// - totalPotentialCost
// - totalPotentialBenefit
// - totalRealizedCost
// - totalRealizedBenefit
// - potentialNetImpact
// - realizedNetImpact
```

### Servicios de Sincronización

#### CategorySyncService
Sincroniza categorías entre Hive y Firestore.

#### TransactionSyncService
Sincroniza transacciones entre Hive y Firestore.

#### Base Sync Pattern
Todos los servicios de sincronización extienden `BaseSyncService` que implementa:
- Detección de cambios
- Sincronización bidireccional
- Resolución de conflictos (last-write-wins)
- Manejo de errores con reintentos

## Características Principales

### 1. Transacciones Recurrentes

Las transacciones recurrentes se generan automáticamente según su regla de recurrencia.

**Configurar transacción recurrente:**

```dart
final recurring = RecurringTransaction(
  id: 'recurring_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Subscripción Netflix',
  amount: 15.99,
  categoryId: 'exp_entertainment',
  type: FinanceCategoryType.expense,
  recurrence: RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    startDate: DateTime.now(),
    dayOfMonth: 5, // Día 5 de cada mes
  ),
  autoGenerate: true,
  active: true,
  createdAt: DateTime.now(),
);

// Guardar en el repositorio
await recurringTransactionStorage.save(recurring, userId);
```

**Generación automática:**

El sistema verifica periódicamente transacciones recurrentes pendientes y las genera automáticamente:

```dart
final recurringService = RecurringTransactionService();
await recurringService.generatePendingTransactions(
  recurringTransactions,
  userId,
);
```

**Detección automática de patrones:**

El sistema puede detectar patrones en transacciones existentes:

```dart
final patterns = await recurringService.detectRecurringPatterns(
  allTransactions,
  minOccurrences: 3,
);

// patterns contiene sugerencias de transacciones recurrentes
for (final pattern in patterns) {
  print('Detectado: ${pattern.title} - ${pattern.recurrenceDescription}');
}
```

### 2. Presupuestos

Los presupuestos permiten establecer límites de gasto por categoría y período.

**Crear presupuesto:**

```dart
final budget = Budget(
  id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
  name: 'Presupuesto Mensual de Comida',
  categoryId: 'exp_food',
  limit: 600.0,
  period: BudgetPeriod.monthly,
  startDate: DateTime(2025, 1, 1),
  alertThreshold: 0.8,  // Alerta al 80%
  rollover: true,        // Transferir saldo no usado
  active: true,
  createdAt: DateTime.now(),
);

await budgetStorage.save(budget, userId);
```

**Configuración de alertas:**

Los presupuestos generan alertas automáticamente cuando:
- Se alcanza el threshold (ej: 80% del límite)
- Se excede el límite (100%)
- Se detectan gastos inusuales en la categoría

**Rollover de saldo:**

Si `rollover = true`, el saldo no gastado se transfiere al siguiente período:

```dart
// Si el presupuesto era $600 y solo se gastó $550
// El siguiente período tendrá un límite de $650 ($600 base + $50 rollover)
```

### 3. Proyecciones de Flujo de Efectivo

El sistema genera proyecciones automáticas basadas en:
- Transacciones recurrentes configuradas
- Histórico de transacciones
- Presupuestos activos

**Generar proyecciones:**

```dart
final forecastProvider = ref.watch(forecastProvider);

// Proyectar los próximos 6 meses
final projections = await forecastProvider.generateProjections(
  startDate: DateTime.now(),
  months: 6,
);

for (final projection in projections) {
  print('${projection.date}: Balance proyectado = ${projection.projectedBalance}');
  print('  Ingresos: ${projection.projectedIncome}');
  print('  Gastos: ${projection.projectedExpenses}');
}
```

**Nivel de confianza:**

Las proyecciones más lejanas tienen menor nivel de confianza. El sistema calcula la confianza basándose en:
- Cantidad de datos históricos disponibles
- Variabilidad de transacciones en el pasado
- Presencia de transacciones recurrentes configuradas

### 4. Vinculación Tarea-Finanzas

Las tareas pueden tener impacto financiero asociado.

**Tarea con costo:**

```dart
final task = Task(
  title: 'Cambiar aceite del auto',
  type: 'once',
  category: 'Hogar',
  priority: 1,
  createdAt: DateTime.now(),
  // Campos financieros
  financialCost: 45.0,
  financialCategoryId: 'exp_transport',
  autoGenerateTransaction: true,  // Crear transacción al completar
  financialNote: 'Mantenimiento regular del vehículo',
);
```

**Tarea con beneficio:**

```dart
final task = Task(
  title: 'Vender libros usados',
  type: 'once',
  category: 'Personal',
  priority: 1,
  createdAt: DateTime.now(),
  financialBenefit: 30.0,
  financialCategoryId: 'inc_other',
  autoGenerateTransaction: true,
);
```

**Tarea con ROI:**

```dart
final task = Task(
  title: 'Curso de programación',
  type: 'once',
  category: 'Personal',
  priority: 2,
  createdAt: DateTime.now(),
  financialCost: 200.0,           // Costo del curso
  financialBenefit: 1000.0,       // Beneficio esperado (aumento salarial)
  financialImpactType: 'deferred', // Beneficio diferido
  financialCategoryId: 'exp_shopping',
);

// ROI automático: (1000 - 200) / 200 = 4.0 (400% de retorno)
print('ROI: ${task.financialROI}%');
```

**Generación automática de transacción:**

Cuando se completa una tarea con `autoGenerateTransaction = true`, el sistema crea automáticamente la transacción correspondiente:

```dart
// Al completar la tarea
task.isCompleted = true;
await taskService.updateTask(task);

// TaskFinanceIntegrationService detecta el cambio y crea la transacción
// La transacción se guarda en Firestore y Hive automáticamente
```

## Guía de Uso

### Ejemplo 1: Sistema Básico de Gastos Personales

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalFinanceScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mis Finanzas')),
      body: Column(
        children: [
          // Resumen
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Balance: \$${financeState.balance.toStringAsFixed(2)}'),
                  Text('Ingresos: \$${financeState.totalIncome.toStringAsFixed(2)}'),
                  Text('Gastos: \$${financeState.totalExpenses.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),

          // Lista de transacciones
          Expanded(
            child: ListView.builder(
              itemCount: financeState.transactions.length,
              itemBuilder: (context, index) {
                final transaction = financeState.transactions[index];
                return ListTile(
                  title: Text(transaction.title),
                  subtitle: Text(transaction.date.toString()),
                  trailing: Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction.isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Botón para agregar transacción
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    // Mostrar diálogo para agregar transacción
    // Ver AddTransactionDialog widget incluido en el proyecto
  }
}
```

### Ejemplo 2: Configurar Presupuesto con Alertas

```dart
// Crear presupuesto mensual de comida
final foodBudget = Budget(
  id: 'budget_food',
  name: 'Alimentación Mensual',
  categoryId: 'exp_food',
  limit: 500.0,
  period: BudgetPeriod.monthly,
  startDate: DateTime.now(),
  alertThreshold: 0.8,  // Alerta al 80% ($400)
  rollover: true,
  active: true,
  createdAt: DateTime.now(),
  note: 'Incluye supermercado y restaurantes',
);

await ref.read(budgetStorageProvider).save(foodBudget, userId);

// El sistema generará alertas automáticamente:
// - Alerta de advertencia al alcanzar $400 (80%)
// - Alerta crítica al exceder $500 (100%)
```

### Ejemplo 3: Transacciones Recurrentes

```dart
// Configurar todas las transacciones recurrentes mensuales
final recurringTransactions = [
  // Salario
  RecurringTransaction(
    id: 'rec_salary',
    title: 'Salario',
    amount: 3000.0,
    categoryId: 'inc_salary',
    type: FinanceCategoryType.income,
    recurrence: RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      dayOfMonth: 1,
    ),
    autoGenerate: true,
    active: true,
    createdAt: DateTime.now(),
  ),

  // Renta
  RecurringTransaction(
    id: 'rec_rent',
    title: 'Renta',
    amount: 800.0,
    categoryId: 'exp_home',
    type: FinanceCategoryType.expense,
    recurrence: RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      dayOfMonth: 5,
    ),
    autoGenerate: true,
    active: true,
    createdAt: DateTime.now(),
  ),

  // Netflix
  RecurringTransaction(
    id: 'rec_netflix',
    title: 'Netflix',
    amount: 15.99,
    categoryId: 'exp_entertainment',
    type: FinanceCategoryType.expense,
    recurrence: RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      startDate: DateTime.now(),
      dayOfMonth: 10,
    ),
    autoGenerate: true,
    active: true,
    createdAt: DateTime.now(),
  ),
];

// Guardar todas
for (final rec in recurringTransactions) {
  await recurringStorage.save(rec, userId);
}

// El servicio generará automáticamente las transacciones cuando llegue la fecha
```

### Ejemplo 4: Tarea con Impacto Financiero

```dart
// Tarea: Ir al gimnasio (tiene costo mensual)
final gymTask = Task(
  title: 'Ir al gimnasio',
  type: 'daily',
  category: 'Salud',
  priority: 2,
  createdAt: DateTime.now(),
  motivation: 'Mejorar mi salud y estado físico',
  reward: 'Sentirme más fuerte y saludable',
  // Impacto financiero
  financialCost: 50.0,  // $50 por membresía mensual (prorrateado)
  financialCategoryId: 'exp_health',
  financialNote: 'Membresía mensual del gimnasio',
  autoGenerateTransaction: false, // No generar transacción diaria
);

// Vincular con transacción recurrente
final gymRecurring = RecurringTransaction(
  id: 'rec_gym',
  title: 'Membresía Gimnasio',
  amount: 50.0,
  categoryId: 'exp_health',
  type: FinanceCategoryType.expense,
  recurrence: RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    startDate: DateTime.now(),
    dayOfMonth: 1,
  ),
  linkedTaskId: gymTask.firestoreId, // Vincular con tarea
  autoGenerate: true,
  active: true,
  createdAt: DateTime.now(),
);

await taskService.saveTask(gymTask);
await recurringStorage.save(gymRecurring, userId);
```

### Ejemplo 5: Análisis Financiero de Tareas

```dart
final integrationService = ref.read(taskFinanceIntegrationServiceProvider);
final allTasks = ref.read(tasksProvider('all'));

// Obtener estadísticas financieras
final stats = integrationService.getFinancialTaskStats(allTasks);

print('Tareas con impacto financiero: ${stats['tasksWithFinancialImpact']}');
print('Tareas completadas con impacto: ${stats['completedWithImpact']}');
print('Costo potencial total: \$${stats['totalPotentialCost']}');
print('Beneficio potencial total: \$${stats['totalPotentialBenefit']}');
print('Impacto neto potencial: \$${stats['potentialNetImpact']}');
print('Impacto neto realizado: \$${stats['realizedNetImpact']}');

// Widget para mostrar ROI de tareas
class TaskFinancialImpactCard extends ConsumerWidget {
  final Task task;

  const TaskFinancialImpactCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!task.hasFinancialImpact) return SizedBox.shrink();

    final roi = task.financialROI;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Impacto Financiero', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            if (task.financialCost != null)
              Text('Costo: \$${task.financialCost!.toStringAsFixed(2)}'),
            if (task.financialBenefit != null)
              Text('Beneficio: \$${task.financialBenefit!.toStringAsFixed(2)}'),
            if (task.netFinancialImpact != null)
              Text(
                'Neto: \$${task.netFinancialImpact!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: task.netFinancialImpact! >= 0 ? Colors.green : Colors.red,
                ),
              ),
            if (roi != null)
              Text('ROI: ${roi.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### Providers

```dart
// Provider principal de finanzas
final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>

// Repositorio de finanzas
final financeRepositoryProvider = Provider<FinanceRepository>

// Almacenamiento local
final categoryStorageProvider = Provider<CategoryStorage>
final transactionStorageProvider = Provider<TransactionStorage>
final recurringTransactionStorageProvider = Provider<RecurringTransactionStorage>
final budgetStorageProvider = Provider<BudgetStorage>
final cashFlowProjectionStorageProvider = Provider<CashFlowProjectionStorage>
final financeAlertStorageProvider = Provider<FinanceAlertStorage>
final taskFinanceLinkStorageProvider = Provider<TaskFinanceLinkStorage>

// Servicios
final taskFinanceIntegrationServiceProvider = Provider<TaskFinanceIntegrationService>
final recurringTransactionServiceProvider = Provider<RecurringTransactionService>
```

### Métodos Principales

#### FinanceNotifier

```dart
// Agregar transacción
Future<void> addTransaction({
  required String title,
  required double amount,
  required DateTime date,
  required String categoryId,
  required FinanceCategoryType type,
  String? note,
})

// Eliminar transacción
Future<void> deleteTransaction(dynamic key)

// Agregar categoría
Future<void> addCategory(FinanceCategory category)
```

#### RecurringTransactionService

```dart
// Detectar patrones recurrentes
Future<List<RecurringTransaction>> detectRecurringPatterns(
  List<Transaction> transactions,
  {int minOccurrences = 3}
)

// Generar transacciones pendientes
Future<void> generatePendingTransactions(
  List<RecurringTransaction> recurringTransactions,
  String userId,
)
```

#### TaskFinanceIntegrationService

```dart
// Generar transacción al completar tarea
Future<String?> onTaskCompleted(Task task)

// Calcular ROI de tarea
double? calculateTaskROI(Task task)

// Sugerir vinculación financiera
Future<List<Transaction>> suggestFinancialLink(Task task)

// Obtener estadísticas financieras de tareas
Map<String, dynamic> getFinancialTaskStats(List<Task> tasks)
```

## Sincronización con Firebase

El sistema de finanzas usa el mismo patrón de sincronización que el resto de AuraList:

1. **Escritura local primero**: Todos los cambios se guardan en Hive inmediatamente
2. **Sincronización asíncrona**: Los datos se sincronizan con Firestore en segundo plano
3. **Resolución de conflictos**: Last-write-wins basado en `lastUpdatedAt`
4. **Cola de reintentos**: Operaciones fallidas se encolan con backoff exponencial

### Estructura en Firestore

```
users/
  {userId}/
    finance_categories/
      {categoryId}/
        - Documento de FinanceCategory

    transactions/
      {transactionId}/
        - Documento de Transaction

    recurring_transactions/
      {recurringId}/
        - Documento de RecurringTransaction

    budgets/
      {budgetId}/
        - Documento de Budget

    cash_flow_projections/
      {projectionId}/
        - Documento de CashFlowProjection

    finance_alerts/
      {alertId}/
        - Documento de FinanceAlert

    task_finance_links/
      {linkId}/
        - Documento de TaskFinanceLink
```

## Mejores Prácticas

### 1. Uso de Transacciones Recurrentes

- Configure transacciones recurrentes para ingresos y gastos fijos
- Use `autoGenerate = true` para automatizar la creación
- Vincule con tareas cuando sea apropiado (ej: membresía de gimnasio)
- Desactive (`active = false`) en lugar de eliminar si ya no aplica

### 2. Gestión de Presupuestos

- Establezca presupuestos realistas basados en historial
- Use `alertThreshold` para recibir avisos tempranos
- Active `rollover` para presupuestos flexibles
- Cree presupuestos globales para control general de gastos

### 3. Vinculación con Tareas

- Use `autoGenerateTransaction = true` solo para tareas puntuales con costo/beneficio claro
- Prefiera vincular con `RecurringTransaction` para gastos recurrentes
- Documente el impacto financiero en `financialNote`
- Use `financialImpactType` para clasificar el tipo de impacto

### 4. Análisis de Datos

- Revise las proyecciones mensualmente
- Analice varianzas entre proyectado y real
- Use las estadísticas de tareas para priorizar actividades rentables
- Monitoree alertas para detectar problemas temprano

### 5. Privacidad y Seguridad

- Los datos financieros solo se sincronizan si el usuario tiene Firebase auth
- Los datos locales están protegidos por el sistema operativo
- No se comparte información financiera con terceros
- El usuario tiene control total sobre sus datos (puede deshabilitar sync)

## Limitaciones Conocidas

1. **Sin multi-moneda**: Actualmente solo soporta una moneda
2. **Sin cuentas bancarias**: No se integra directamente con bancos
3. **Sin inversiones**: No maneja portafolios de inversión
4. **Proyecciones simples**: Las proyecciones usan algoritmos básicos, no machine learning
5. **Sin presupuestos compartidos**: Cada usuario tiene presupuestos independientes

## Roadmap Futuro

- Soporte multi-moneda con conversión automática
- Categorías personalizables con subcategorías
- Reportes y gráficos avanzados
- Exportación a CSV/PDF
- Integración con Open Banking APIs
- Machine learning para mejores proyecciones
- Presupuestos compartidos entre usuarios
- Metas de ahorro con tracking visual
- Detección de fraude y gastos duplicados

## Soporte

Para reportar problemas o solicitar características, por favor abre un issue en el repositorio de GitHub.

---

**Última actualización**: Febrero 2026
**Versión del sistema**: 2.0.0
