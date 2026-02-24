import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../features/finance/models/transaction.dart';
import '../features/finance/models/finance_category.dart';
import '../features/finance/providers/finance_provider.dart';
import 'logger_service.dart';

/// Servicio de integración entre tareas y finanzas
class TaskFinanceIntegrationService {
  final Ref _ref;

  TaskFinanceIntegrationService(this._ref);

  /// Genera una transacción automáticamente al completar una tarea
  /// si tiene configurado autoGenerateTransaction = true
  Future<String?> onTaskCompleted(Task task) async {
    try {
      // Verificar si debe generar transacción
      if (!task.autoGenerateTransaction || !task.hasFinancialImpact) {
        return null;
      }

      // Determinar el monto y tipo de transacción
      double amount;
      FinanceCategoryType transactionType;
      String categoryId;

      // Si tiene beneficio, crear ingreso
      // Si tiene costo, crear gasto
      // Si tiene ambos, crear el neto
      if (task.financialBenefit != null && task.financialCost == null) {
        amount = task.financialBenefit!;
        transactionType = FinanceCategoryType.income;
        categoryId = task.financialCategoryId ?? 'inc_other';
      } else if (task.financialCost != null && task.financialBenefit == null) {
        amount = task.financialCost!;
        transactionType = FinanceCategoryType.expense;
        categoryId = task.financialCategoryId ?? 'exp_shopping';
      } else if (task.financialBenefit != null && task.financialCost != null) {
        // Ambos presentes - usar el neto
        final net = task.netFinancialImpact!;
        if (net >= 0) {
          amount = net;
          transactionType = FinanceCategoryType.income;
          categoryId = task.financialCategoryId ?? 'inc_other';
        } else {
          amount = net.abs();
          transactionType = FinanceCategoryType.expense;
          categoryId = task.financialCategoryId ?? 'exp_shopping';
        }
      } else {
        return null;
      }

      // Crear la transacción
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      await _ref.read(financeProvider.notifier).addTransaction(
            title: task.title,
            amount: amount,
            date: DateTime.now(),
            categoryId: categoryId,
            type: transactionType,
            note: 'Generado automáticamente al completar tarea',
          );

      LoggerService().info(
        'TaskFinanceIntegration',
        'Transacción generada automáticamente para tarea: ${task.title}',
      );

      return transactionId;
    } catch (e, stack) {
      LoggerService().error(
        'TaskFinanceIntegration',
        'Error al generar transacción automática',
        error: e,
        stack: stack,
      );
      return null;
    }
  }

  /// Calcula el ROI (Return on Investment) de una tarea
  /// Retorna el porcentaje de retorno si está disponible
  double? calculateTaskROI(Task task) {
    return task.financialROI;
  }

  /// Sugiere vincular una tarea existente con una transacción
  /// basándose en título, fecha y monto
  Future<List<Transaction>> suggestFinancialLink(Task task) async {
    try {
      if (!task.hasFinancialImpact) return [];

      final financeState = _ref.read(financeProvider);
      final allTransactions = financeState.transactions;

      // Filtrar transacciones similares
      final suggestions = allTransactions.where((transaction) {
        // Comparar título (similitud básica)
        final titleMatch = transaction.title
            .toLowerCase()
            .contains(task.title.toLowerCase().split(' ').first);

        // Comparar fecha (mismo día si la tarea tiene dueDate)
        bool dateMatch = true;
        if (task.dueDate != null) {
          final taskDate = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          final transactionDate = DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          );
          dateMatch = taskDate == transactionDate;
        }

        // Comparar monto (aproximado)
        bool amountMatch = false;
        if (task.financialCost != null) {
          amountMatch = (transaction.amount - task.financialCost!).abs() < 0.01;
        } else if (task.financialBenefit != null) {
          amountMatch = (transaction.amount - task.financialBenefit!).abs() < 0.01;
        }

        return (titleMatch || amountMatch) && dateMatch;
      }).toList();

      return suggestions;
    } catch (e, stack) {
      LoggerService().error(
        'TaskFinanceIntegration',
        'Error al sugerir vinculación financiera',
        error: e,
        stack: stack,
      );
      return [];
    }
  }

  /// Obtiene estadísticas financieras de todas las tareas
  Map<String, dynamic> getFinancialTaskStats(List<Task> tasks) {
    final tasksWithImpact = tasks.where((t) => t.hasFinancialImpact).toList();
    final completedWithImpact =
        tasksWithImpact.where((t) => t.isCompleted).toList();

    double totalPotentialCost = 0;
    double totalPotentialBenefit = 0;
    double totalRealizedCost = 0;
    double totalRealizedBenefit = 0;

    for (final task in tasksWithImpact) {
      totalPotentialCost += task.financialCost ?? 0;
      totalPotentialBenefit += task.financialBenefit ?? 0;

      if (task.isCompleted) {
        totalRealizedCost += task.financialCost ?? 0;
        totalRealizedBenefit += task.financialBenefit ?? 0;
      }
    }

    return {
      'tasksWithFinancialImpact': tasksWithImpact.length,
      'completedWithImpact': completedWithImpact.length,
      'totalPotentialCost': totalPotentialCost,
      'totalPotentialBenefit': totalPotentialBenefit,
      'totalRealizedCost': totalRealizedCost,
      'totalRealizedBenefit': totalRealizedBenefit,
      'potentialNetImpact': totalPotentialBenefit - totalPotentialCost,
      'realizedNetImpact': totalRealizedBenefit - totalRealizedCost,
    };
  }
}

/// Provider para el servicio de integración
final taskFinanceIntegrationServiceProvider =
    Provider<TaskFinanceIntegrationService>((ref) {
  return TaskFinanceIntegrationService(ref);
});
