import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_account.dart';
import '../models/savings_projection.dart';
import '../repositories/finance_repository.dart';
import '../services/savings_simulation_service.dart';
import 'finance_provider.dart';
import '../../../services/error_handler.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';

/// Estado del módulo de cuentas de ahorro e inversión.
class SavingsState {
  final List<SavingsAccount> accounts;
  final bool isLoading;

  const SavingsState({this.accounts = const [], this.isLoading = false});

  SavingsState copyWith({List<SavingsAccount>? accounts, bool? isLoading}) {
    return SavingsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  final FinanceRepository _repository;
  final Ref _ref;
  StreamSubscription? _subscription;

  SavingsNotifier({required FinanceRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const SavingsState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.init();
      await _repository.init();

      _subscription?.cancel();
      _subscription = _repository.watchSavingsAccounts().listen(
        (accounts) {
          final sorted = [...accounts]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = SavingsState(accounts: sorted, isLoading: false);
        },
        onError: (Object e, StackTrace stack) {
          ErrorHandler().handle(
            e,
            type: ErrorType.database,
            message: 'Error al observar cuentas de ahorro',
            stackTrace: stack,
          );
          state = state.copyWith(isLoading: false);
        },
      );

      // Sync inicial si hay usuario autenticado
      final userId = _getUserId();
      if (userId.isNotEmpty) {
        unawaited(_repository.performFullSync(userId));
      }
    } catch (e, stack) {
      ErrorHandler().handle(
        e,
        type: ErrorType.database,
        message: 'Error al inicializar SavingsNotifier',
        stackTrace: stack,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  String _getUserId() {
    try {
      final authService = _ref.read(authServiceProvider);
      if (authService.currentUser != null) {
        return authService.currentUser!.uid;
      }
    } catch (_) {}
    return '';
  }

  Future<void> addAccount({
    required String name,
    required SavingsAccountType type,
    double initialBalance = 0.0,
    double currentBalance = 0.0,
    double monthlyContribution = 0.0,
    double annualInterestRate = 0.0,
  }) async {
    final userId = _getUserId();
    final now = DateTime.now();

    final account = SavingsAccount(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance > 0 && currentBalance == 0
          ? initialBalance
          : currentBalance,
      monthlyContribution: monthlyContribution,
      annualInterestRate: annualInterestRate,
      createdAt: now,
    );

    await _repository.saveSavingsAccount(account, userId);
  }

  Future<void> updateAccount(SavingsAccount account) async {
    final userId = _getUserId();
    final updated = account.copyWith(lastUpdatedAt: DateTime.now());
    await _repository.saveSavingsAccount(updated, userId);
  }

  Future<void> deleteAccount(String id) async {
    final userId = _getUserId();
    await _repository.deleteSavingsAccount(id, userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final savingsProvider = StateNotifierProvider<SavingsNotifier, SavingsState>((
  ref,
) {
  try {
    final repository = ref.watch(financeRepositoryProvider);
    return SavingsNotifier(repository: repository, ref: ref);
  } catch (e, stack) {
    final errorHandler = ref.watch(errorHandlerProvider);
    errorHandler.handle(
      e,
      type: ErrorType.database,
      message: 'Error al crear SavingsNotifier',
      stackTrace: stack,
    );
    rethrow;
  }
});

/// Servicio de simulación de interés compuesto.
final savingsSimulationServiceProvider = Provider<SavingsSimulationService>(
  (ref) => SavingsSimulationService(),
);

/// Cuentas activas sin borrado lógico.
final activeSavingsAccountsProvider = Provider<List<SavingsAccount>>((ref) {
  final accounts = ref.watch(savingsProvider.select((s) => s.accounts));
  return accounts.where((a) => !a.deleted).toList();
});

/// Proyección consolidada (30 años) de todas las cuentas.
final combinedSavingsProjectionProvider = Provider<SavingsProjection>((ref) {
  final accounts = ref.watch(activeSavingsAccountsProvider);
  final service = ref.watch(savingsSimulationServiceProvider);
  return service.projectCombined(accounts);
});

/// Estadísticas generales y promedios de todas las cuentas.
final savingsOverallStatsProvider = Provider<SavingsOverallStats>((ref) {
  final accounts = ref.watch(activeSavingsAccountsProvider);
  final service = ref.watch(savingsSimulationServiceProvider);
  return service.overallStats(accounts);
});

/// Proyección mensual de una cuenta específica.
final savingsAccountProjectionProvider =
    Provider.family<SavingsProjection, String>((ref, accountId) {
      final accounts = ref.watch(activeSavingsAccountsProvider);
      final account = accounts.where((a) => a.id == accountId).firstOrNull;
      final service = ref.watch(savingsSimulationServiceProvider);
      if (account == null) {
        return service.projectCombined(const []);
      }
      return service.projectAccount(account);
    });
