import 'package:uuid/uuid.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../../../models/recurrence_rule.dart';
import '../data/recurring_transaction_storage.dart';
import '../data/transaction_storage.dart';
import '../../../services/error_handler.dart';
import '../../../services/logger_service.dart';

/// Servicio para gestionar transacciones recurrentes y detectar patrones.
class RecurringTransactionService {
  final RecurringTransactionStorage _storage;
  final TransactionStorage _transactionStorage;
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();
  final Uuid _uuid = const Uuid();

  static const String _tag = 'RecurringTransactionService';
  static const int _minTransactionsForPattern = 3;
  static const double _levenshteinThreshold = 0.7; // 70% similarity
  static const double _amountVarianceThreshold = 0.15; // 15% variance allowed

  RecurringTransactionService({
    required RecurringTransactionStorage storage,
    required TransactionStorage transactionStorage,
    required ErrorHandler errorHandler,
  })  : _storage = storage,
        _transactionStorage = transactionStorage,
        _errorHandler = errorHandler;

  /// Detecta patrones recurrentes en el historial de transacciones.
  /// Retorna lista de transacciones recurrentes auto-detectadas.
  Future<List<RecurringTransaction>> detectRecurringPatterns() async {
    try {
      _logger.info(_tag, 'Starting pattern detection');

      final transactions = await _transactionStorage.getAll();
      if (transactions.length < _minTransactionsForPattern) {
        _logger.debug(_tag, 'Not enough transactions for pattern detection');
        return [];
      }

      // Agrupar transacciones por similitud
      final groups = _groupSimilarTransactions(transactions);

      // Detectar patrones temporales en cada grupo
      final patterns = <RecurringTransaction>[];
      for (final group in groups) {
        if (group.length >= _minTransactionsForPattern) {
          final pattern = _detectTemporalPattern(group);
          if (pattern != null) {
            patterns.add(pattern);
          }
        }
      }

      _logger.info(_tag, 'Detected ${patterns.length} recurring patterns');
      return patterns;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al detectar patrones recurrentes',
      );
      return [];
    }
  }

  /// Agrupa transacciones similares usando distancia de Levenshtein.
  List<List<Transaction>> _groupSimilarTransactions(List<Transaction> transactions) {
    final groups = <List<Transaction>>[];
    final processed = <Transaction>{};

    for (final transaction in transactions) {
      if (processed.contains(transaction)) continue;

      final similarGroup = <Transaction>[transaction];
      processed.add(transaction);

      // Buscar transacciones similares
      for (final other in transactions) {
        if (processed.contains(other)) continue;

        if (_areTransactionsSimilar(transaction, other)) {
          similarGroup.add(other);
          processed.add(other);
        }
      }

      if (similarGroup.length >= _minTransactionsForPattern) {
        groups.add(similarGroup);
      }
    }

    return groups;
  }

  /// Verifica si dos transacciones son similares.
  bool _areTransactionsSimilar(Transaction a, Transaction b) {
    // Mismo tipo (ingreso/gasto)
    if (a.type != b.type) return false;

    // Misma categoría
    if (a.categoryId != b.categoryId) return false;

    // Similitud de título (Levenshtein)
    final titleSimilarity = _calculateStringSimilarity(a.title, b.title);
    if (titleSimilarity < _levenshteinThreshold) return false;

    // Monto similar (dentro del umbral de varianza)
    final amountDiff = (a.amount - b.amount).abs();
    final avgAmount = (a.amount + b.amount) / 2;
    final amountVariance = avgAmount > 0 ? amountDiff / avgAmount : 0;
    if (amountVariance > _amountVarianceThreshold) return false;

    return true;
  }

  /// Calcula similitud entre dos cadenas usando distancia de Levenshtein.
  /// Retorna valor entre 0.0 y 1.0 (1.0 = idénticos).
  double _calculateStringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();

    final distance = _levenshteinDistance(aLower, bLower);
    final maxLength = aLower.length > bLower.length ? aLower.length : bLower.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calcula distancia de Levenshtein entre dos cadenas.
  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = _min3(
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        );
      }
    }

    return matrix[a.length][b.length];
  }

  int _min3(int a, int b, int c) {
    return a < b ? (a < c ? a : c) : (b < c ? b : c);
  }

  /// Detecta el patrón temporal en un grupo de transacciones similares.
  RecurringTransaction? _detectTemporalPattern(List<Transaction> group) {
    if (group.length < _minTransactionsForPattern) return null;

    // Ordenar por fecha
    final sorted = List<Transaction>.from(group)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calcular intervalos entre transacciones
    final intervals = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final daysDiff = sorted[i].date.difference(sorted[i - 1].date).inDays;
      intervals.add(daysDiff);
    }

    // Detectar frecuencia basada en intervalos
    final frequency = _detectFrequency(intervals);
    if (frequency == null) return null;

    // Calcular monto promedio
    final avgAmount = group.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    ) / group.length;

    // Calcular nivel de confianza basado en consistencia
    final confidence = _calculatePatternConfidence(intervals, group);

    // Usar la primera transacción como base
    final first = sorted.first;
    final recurrence = _createRecurrenceRule(frequency, first.date);

    return RecurringTransaction(
      id: _uuid.v4(),
      title: first.title,
      amount: avgAmount,
      categoryId: first.categoryId,
      type: first.type,
      recurrence: recurrence,
      autoGenerate: false, // Requiere confirmación del usuario
      active: false, // Inactivo hasta que el usuario lo active
      note: 'Patrón detectado automáticamente (${group.length} transacciones)',
      createdAt: DateTime.now(),
    );
  }

  /// Detecta la frecuencia basada en intervalos de días.
  RecurrenceFrequency? _detectFrequency(List<int> intervals) {
    if (intervals.isEmpty) return null;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Daily: 1 día (±1 día de tolerancia)
    if (_isNear(avgInterval, 1, 1)) {
      return RecurrenceFrequency.daily;
    }

    // Weekly: 7 días (±2 días de tolerancia)
    if (_isNear(avgInterval, 7, 2)) {
      return RecurrenceFrequency.weekly;
    }

    // Monthly: ~30 días (±5 días de tolerancia)
    if (_isNear(avgInterval, 30, 5)) {
      return RecurrenceFrequency.monthly;
    }

    // Yearly: ~365 días (±15 días de tolerancia)
    if (_isNear(avgInterval, 365, 15)) {
      return RecurrenceFrequency.yearly;
    }

    return null;
  }

  bool _isNear(double value, double target, double tolerance) {
    return (value - target).abs() <= tolerance;
  }

  /// Calcula el nivel de confianza del patrón detectado (0.0 - 1.0).
  double _calculatePatternConfidence(List<int> intervals, List<Transaction> group) {
    if (intervals.isEmpty) return 0.0;

    // Factor 1: Consistencia de intervalos (60% del score)
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.fold<double>(
      0,
      (sum, i) => sum + ((i - avgInterval) * (i - avgInterval)),
    ) / intervals.length;
    final stdDev = variance > 0 ? (variance).abs().toDouble() : 0.0;
    final coefficientOfVariation = avgInterval > 0 ? stdDev / avgInterval : 1.0;
    final intervalConsistency = (1.0 - coefficientOfVariation).clamp(0.0, 1.0);

    // Factor 2: Consistencia de montos (20% del score)
    final avgAmount = group.fold<double>(0, (sum, t) => sum + t.amount) / group.length;
    final amountVariance = group.fold<double>(
      0,
      (sum, t) => sum + ((t.amount - avgAmount) * (t.amount - avgAmount)),
    ) / group.length;
    final amountStdDev = amountVariance > 0 ? (amountVariance).abs().toDouble() : 0.0;
    final amountCV = avgAmount > 0 ? amountStdDev / avgAmount : 1.0;
    final amountConsistency = (1.0 - amountCV).clamp(0.0, 1.0);

    // Factor 3: Número de ocurrencias (20% del score)
    final occurrenceScore = (group.length / (_minTransactionsForPattern + 5))
        .clamp(0.0, 1.0);

    // Combinar factores
    final confidence = (intervalConsistency * 0.6) +
                      (amountConsistency * 0.2) +
                      (occurrenceScore * 0.2);

    return confidence;
  }

  /// Crea una regla de recurrencia basada en la frecuencia detectada.
  RecurrenceRule _createRecurrenceRule(
    RecurrenceFrequency frequency,
    DateTime startDate,
  ) {
    return RecurrenceRule(
      frequency: frequency,
      interval: 1,
      startDate: startDate,
    );
  }

  /// Genera transacciones futuras desde las recurrentes activas.
  /// Retorna lista de transacciones generadas.
  Future<List<Transaction>> generateUpcomingTransactions({
    DateTime? until,
    int maxTransactions = 100,
  }) async {
    try {
      final endDate = until ?? DateTime.now().add(const Duration(days: 90));
      final recurring = await _storage.getActive();
      final generated = <Transaction>[];

      for (final recurrent in recurring) {
        if (!recurrent.autoGenerate) continue;

        final next = recurrent.nextOccurrence();
        if (next == null) continue;

        // Generar transacciones hasta la fecha límite
        final occurrences = recurrent.recurrence.nextOccurrences(
          recurrent.lastGenerated ?? DateTime.now(),
          maxTransactions,
        );

        for (final date in occurrences) {
          if (date.isAfter(endDate)) break;

          final transaction = Transaction(
            id: _uuid.v4(),
            title: recurrent.title,
            amount: recurrent.amount,
            date: date,
            categoryId: recurrent.categoryId,
            type: recurrent.type,
            note: 'Generada automáticamente desde recurrente: ${recurrent.title}',
            createdAt: DateTime.now(),
          );

          await _transactionStorage.save(transaction);
          generated.add(transaction);

          // Actualizar última generación
          recurrent.lastGenerated = date;
          await _storage.save(recurrent);
        }
      }

      _logger.info(_tag, 'Generated ${generated.length} upcoming transactions');
      return generated;
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al generar transacciones futuras',
      );
      return [];
    }
  }

  /// Guarda una transacción recurrente.
  Future<void> save(RecurringTransaction transaction) async {
    try {
      await _storage.save(transaction);
      _logger.debug(_tag, 'Saved recurring transaction: ${transaction.id}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al guardar transacción recurrente',
      );
      rethrow;
    }
  }

  /// Actualiza una transacción recurrente.
  Future<void> update(RecurringTransaction transaction) async {
    try {
      transaction.lastUpdatedAt = DateTime.now();
      await _storage.save(transaction);
      _logger.debug(_tag, 'Updated recurring transaction: ${transaction.id}');
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al actualizar transacción recurrente',
      );
      rethrow;
    }
  }

  /// Elimina una transacción recurrente (soft delete).
  Future<void> delete(String id) async {
    try {
      final transaction = await _storage.getById(id);
      if (transaction != null && transaction.key != null) {
        await _storage.delete(transaction.key);
        _logger.debug(_tag, 'Deleted recurring transaction: $id');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al eliminar transacción recurrente',
      );
      rethrow;
    }
  }

  /// Pausa una transacción recurrente.
  Future<void> pause(String id) async {
    try {
      final transaction = await _storage.getById(id);
      if (transaction != null) {
        final updated = transaction.copyWith(active: false);
        await _storage.save(updated);
        _logger.debug(_tag, 'Paused recurring transaction: $id');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al pausar transacción recurrente',
      );
      rethrow;
    }
  }

  /// Reanuda una transacción recurrente.
  Future<void> resume(String id) async {
    try {
      final transaction = await _storage.getById(id);
      if (transaction != null) {
        final updated = transaction.copyWith(active: true);
        await _storage.save(updated);
        _logger.debug(_tag, 'Resumed recurring transaction: $id');
      }
    } catch (e, stack) {
      _errorHandler.handle(
        e,
        type: ErrorType.database,
        stackTrace: stack,
        userMessage: 'Error al reanudar transacción recurrente',
      );
      rethrow;
    }
  }

  /// Obtiene todas las transacciones recurrentes.
  Future<List<RecurringTransaction>> getAll() => _storage.getAll();

  /// Obtiene las transacciones recurrentes activas.
  Future<List<RecurringTransaction>> getActive() => _storage.getActive();

  /// Obtiene transacciones recurrentes por categoría.
  Future<List<RecurringTransaction>> getByCategory(String categoryId) =>
      _storage.getByCategory(categoryId);
}
