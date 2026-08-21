import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/responsive/breakpoints.dart';
import '../models/task_model.dart';
import '../features/finance/models/transaction.dart';
import '../features/finance/providers/finance_provider.dart';
import '../providers/task_provider.dart';

class CalendarView extends ConsumerStatefulWidget {
  final void Function(DateTime date)? onDateSelected;
  final void Function(Task task)? onTaskTap;

  const CalendarView({super.key, this.onDateSelected, this.onTaskTap});

  @override
  ConsumerState<CalendarView> createState() => CalendarViewState();
}

class CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  /// Jumps to today's date, updating both the current month and selected date.
  void jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = now;
    });
    widget.onDateSelected?.call(now);
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday; // 1=Lun, 7=Dom

    final List<DateTime?> days = [];

    // Días vacíos antes del primer día
    for (int i = 1; i < startWeekday; i++) {
      days.add(null);
    }

    // Días del mes
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  List<Task> _getTasksForDate(DateTime date, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
          task.dueDate!.month == date.month &&
          task.dueDate!.day == date.day;
    }).toList();
  }

  List<Transaction> _getTransactionsForDate(
    DateTime date,
    List<Transaction> transactions,
  ) {
    return transactions.where((tx) {
      return tx.date.year == date.year &&
          tx.date.month == date.month &&
          tx.date.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(unifiedAllTasksProvider);
    final financeState = ref.watch(financeProvider);
    final allTransactions = financeState.transactions;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    final colorScheme = Theme.of(context).colorScheme;
    final days = _getDaysInMonth();
    final now = DateTime.now();
    final horizontalPadding = context.horizontalPadding;

    final selectedTasks = _selectedDate != null
        ? _getTasksForDate(_selectedDate!, allTasks)
        : <Task>[];
    final selectedTransactions = _selectedDate != null
        ? _getTransactionsForDate(_selectedDate!, allTransactions)
        : <Transaction>[];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con navegación de mes
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Mes anterior',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    }),
                  ),
                ),
                Semantics(
                  label:
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  header: true,
                  child: Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Mes siguiente',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month + 1,
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Días de la semana
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Grid de días
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                if (date == null) return const SizedBox();

                final isToday =
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final isSelected =
                    _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                final tasksForDay = _getTasksForDate(date, allTasks);
                final txsForDay = _getTransactionsForDate(date, allTransactions);

                final hasTask = tasksForDay.isNotEmpty;
                final hasExpense = txsForDay.any((tx) => tx.amount < 0);
                final hasIncome = txsForDay.any((tx) => tx.amount > 0);
                final completedCount =
                    tasksForDay.where((t) => t.isCompleted).length;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    widget.onDateSelected?.call(date);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? colorScheme.onPrimary : null,
                            fontWeight:
                                isToday || isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        // Indicadores de eventos (puntos de color)
                        Positioned(
                          bottom: 3,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Punto de tareas
                              if (hasTask)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: completedCount == tasksForDay.length
                                        ? Colors.green
                                        : (isSelected ? Colors.white : colorScheme.primary),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              // Punto de gasto
                              if (hasExpense)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              // Punto de ingreso
                              if (hasIncome)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: const BoxDecoration(
                                    color: Colors.lightGreenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Detalle del día seleccionado (Tareas + Finanzas unificadas)
          if (_selectedDate != null) ...[
            const Divider(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Día: ${_selectedDate!.day} de ${_getMonthName(_selectedDate!.month)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${selectedTasks.length} tareas · ${selectedTransactions.length} movs',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 1. Tareas del Día
            if (selectedTasks.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Icon(Icons.checklist, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Tareas (${selectedTasks.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ...selectedTasks.map(
                (task) => ListTile(
                  dense: true,
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isCompleted ? Colors.green : colorScheme.primary,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(task.typeLabel),
                  onTap: () => widget.onTaskTap?.call(task),
                ),
              ),
            ],

            // 2. Movimientos Financieros del Día
            if (selectedTransactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                    const Text(
                      'Movimientos Financieros',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ...selectedTransactions.map((tx) {
                final isIncome = tx.amount > 0;
                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isIncome ? Colors.green : Colors.redAccent)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: isIncome ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  title: Text(tx.title.isNotEmpty ? tx.title : 'Sin título'),
                  subtitle: Text(DateFormat('HH:mm').format(tx.date)),
                  trailing: Text(
                    currencyFormat.format(tx.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isIncome ? Colors.green : Colors.redAccent,
                    ),
                  ),
                );
              }),
            ],

            // 3. Estado vacío del día
            if (selectedTasks.isEmpty && selectedTransactions.isEmpty)
              Padding(
                padding: EdgeInsets.all(horizontalPadding * 2),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 40,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sin actividades ni movimientos para este día',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }
}
