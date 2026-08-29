import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/savings_account.dart';
import '../providers/savings_provider.dart';

class AddSavingsAccountDialog extends ConsumerStatefulWidget {
  final SavingsAccount? account;
  final bool? isBottomSheet;

  const AddSavingsAccountDialog({
    super.key,
    this.account,
    this.isBottomSheet,
  });

  /// Muestra el modal de manera adaptativa:
  /// - En móviles (< 600px): Modal Bottom Sheet moderno.
  /// - En escritorio/tablet (>= 600px): Diálogo flotante centrado.
  static Future<void> show(
    BuildContext context, {
    SavingsAccount? account,
  }) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (ctx) => AddSavingsAccountDialog(
          account: account,
          isBottomSheet: true,
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => AddSavingsAccountDialog(
          account: account,
          isBottomSheet: false,
        ),
      );
    }
  }

  @override
  ConsumerState<AddSavingsAccountDialog> createState() =>
      _AddSavingsAccountDialogState();
}

class _AddSavingsAccountDialogState
    extends ConsumerState<AddSavingsAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _initialController;
  late final TextEditingController _currentController;
  late final TextEditingController _contributionController;
  late final TextEditingController _rateController;

  late SavingsAccountType _type;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _type = a?.type ?? SavingsAccountType.savings;
    _nameController = TextEditingController(text: a?.name ?? '');
    _initialController = TextEditingController(
      text: a == null ? '' : _formatAmount(a.initialBalance),
    );
    _currentController = TextEditingController(
      text: a == null ? '' : _formatAmount(a.currentBalance),
    );
    _contributionController = TextEditingController(
      text: a == null ? '' : _formatAmount(a.monthlyContribution),
    );
    _rateController = TextEditingController(
      text: a == null ? '' : _formatRate(a.annualInterestRate),
    );
  }

  String _formatAmount(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _formatRate(double v) => v.toStringAsFixed(2);

  @override
  void dispose() {
    _nameController.dispose();
    _initialController.dispose();
    _currentController.dispose();
    _contributionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  double _parseDouble(TextEditingController c) {
    final text = c.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final initialBalance = _parseDouble(_initialController);
    final currentBalance = _parseDouble(_currentController);
    final monthlyContribution = _parseDouble(_contributionController);
    final annualInterestRate = _parseDouble(_rateController);

    final notifier = ref.read(savingsProvider.notifier);

    if (_isEditing) {
      await notifier.updateAccount(
        widget.account!.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          initialBalance: initialBalance,
          currentBalance: currentBalance,
          monthlyContribution: monthlyContribution,
          annualInterestRate: annualInterestRate,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.addAccount(
        name: _nameController.text.trim(),
        type: _type,
        initialBalance: initialBalance,
        currentBalance: currentBalance == 0 ? initialBalance : currentBalance,
        monthlyContribution: monthlyContribution,
        annualInterestRate: annualInterestRate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = widget.isBottomSheet ?? (mediaQuery.size.width < 600);

    final isSavings = _type == SavingsAccountType.savings;
    final primaryColor = isSavings ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    final contentWidget = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector Tipo (Ahorro / Inversión)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = SavingsAccountType.savings),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSavings
                            ? (isDark ? const Color(0xFF065F46) : const Color(0xFF10B981))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSavings
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 18,
                            color: isSavings
                                ? Colors.white
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ahorro',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSavings ? FontWeight.bold : FontWeight.w500,
                              color: isSavings
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _type = SavingsAccountType.investment),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isSavings
                            ? (isDark ? const Color(0xFF1E40AF) : const Color(0xFF3B82F6))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !isSavings
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: !isSavings
                                ? Colors.white
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Inversión',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !isSavings ? FontWeight.bold : FontWeight.w500,
                              color: !isSavings
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nombre de la cuenta
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la cuenta',
              hintText: 'Ej: Fondo de emergencia, Inversión indexada',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              filled: true,
              fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingresa un nombre' : null,
          ),
          const SizedBox(height: 12),

          // Fila: Saldo Inicial y Saldo Actual
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _initialController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Saldo inicial',
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _currentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Saldo actual',
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fila: Aportación mensual y Tasa de interés
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contributionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Aportación/mes',
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Interés anual',
                    suffixText: '%',
                    hintText: 'Ej: 4.5',
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900.withValues(alpha: 0.6) : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Info de proyección
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_graph_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proyectaremos el crecimiento con interés compuesto mensual.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Botón Principal
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text(
              _isEditing ? 'Guardar Cambios' : 'Crear Cuenta',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );

    final headerBar = Row(
      children: [
        Icon(
          isSavings ? Icons.savings_outlined : Icons.trending_up_rounded,
          color: primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          _isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.90,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: mediaQuery.viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                headerBar,
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: contentWidget,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.90,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            headerBar,
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: contentWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
