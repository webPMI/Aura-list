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

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(
                'Ver',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
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
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primaryContainer,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Full content
          Text(
            'Documento completo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              content.trim(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.6,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
