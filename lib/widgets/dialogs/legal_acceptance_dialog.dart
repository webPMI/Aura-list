import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../core/constants/legal/terms_of_service.dart';
import '../../core/constants/legal/privacy_policy.dart';

/// Shows a full-screen dialog for legal acceptance on first launch.
///
/// Returns true if user accepted, false if dismissed.
///
/// Example usage:
/// ```dart
/// final accepted = await showLegalAcceptanceDialog(context: context, ref: ref);
/// if (accepted) {
///   // Proceed with app
/// }
/// ```
Future<bool> showLegalAcceptanceDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => _LegalAcceptanceDialog(ref: ref),
    ),
  );
  return result ?? false;
}

class _LegalAcceptanceDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _LegalAcceptanceDialog({required this.ref});

  @override
  ConsumerState<_LegalAcceptanceDialog> createState() =>
      _LegalAcceptanceDialogState();
}

class _LegalAcceptanceDialogState extends ConsumerState<_LegalAcceptanceDialog>
    with SingleTickerProviderStateMixin {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canContinue => _acceptedTerms && _acceptedPrivacy;

  Future<void> _onAccept() async {
    if (!_canContinue) return;

    setState(() => _isLoading = true);

    try {
      final dbService = widget.ref.read(databaseServiceProvider);
      await dbService.acceptLegal();

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App icon/logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenido a AuraList',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Antes de continuar, por favor lee y acepta nuestros terminos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimaryContainer,
                unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                tabs: const [
                  Tab(text: 'Terminos'),
                  Tab(text: 'Privacidad'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsContent(),
                  _buildPrivacyContent(),
                ],
              ),
            ),

            // Checkboxes and button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Terms checkbox
                  _buildCheckbox(
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() => _acceptedTerms = value ?? false);
                    },
                    label: 'He leido y acepto los Terminos y Condiciones',
                    onTap: () => _tabController.animateTo(0),
                  ),
                  const SizedBox(height: 12),

                  // Privacy checkbox
                  _buildCheckbox(
                    value: _acceptedPrivacy,
                    onChanged: (value) {
                      setState(() => _acceptedPrivacy = value ?? false);
                    },
                    label: 'He leido y acepto la Politica de Privacidad',
                    onTap: () => _tabController.animateTo(1),
                  ),
                  const SizedBox(height: 24),

                  // Continue button
                  FilledButton(
                    onPressed: _canContinue && !_isLoading ? _onAccept : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Continuar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      checked: value,
      enabled: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant,
              width: value ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox mas grande y accesible
              SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Texto del label
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Boton "Ver" mas visible
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Ver'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return _buildLegalContent(
      title: 'Terminos y Condiciones',
      content: termsOfServiceEs,
      summary: termsSummaryEs,
    );
  }

  Widget _buildPrivacyContent() {
    return _buildLegalContent(
      title: 'Politica de Privacidad',
      content: privacyPolicyEs,
      summary: privacySummaryEs,
    );
  }

  Widget _buildLegalContent({
    required String title,
    required String content,
    required String summary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Summary card con mejor contraste y legibilidad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize_rounded,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Resumen Ejecutivo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summary.trim(),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Divider con label
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: colorScheme.outlineVariant,
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'DOCUMENTO COMPLETO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: colorScheme.outlineVariant,
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full content con mejor legibilidad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: SelectableText(
              content.trim(),
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
                color: colorScheme.onSurface.withValues(alpha: 0.87),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
