import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Shows a confirmation dialog for account deletion.
///
/// Returns true if account was successfully deleted, false otherwise.
///
/// Example usage:
/// ```dart
/// final deleted = await showDeleteAccountDialog(context: context, ref: ref);
/// if (deleted) {
///   // Account was deleted, navigate to login or home
/// }
/// ```
Future<bool> showDeleteAccountDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DeleteAccountDialog(ref: ref),
  );
  return result ?? false;
}

class _DeleteAccountDialog extends StatefulWidget {
  final WidgetRef ref;

  const _DeleteAccountDialog({required this.ref});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static const String _confirmationWord = 'ELIMINAR';

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _confirmController.text.trim().toUpperCase() == _confirmationWord;

  Future<void> _deleteAccount() async {
    if (!_canDelete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = widget.ref.read(authServiceProvider);
      final dbService = widget.ref.read(databaseServiceProvider);

      final success = await authService.deleteAccount(dbService);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta eliminada exitosamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'No se pudo eliminar la cuenta. Intenta de nuevo.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al eliminar cuenta: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Eliminar Cuenta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Advertencia',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta accion es permanente e irreversible. Se eliminaran:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildWarningItem('Todas tus tareas'),
                  _buildWarningItem('Todas tus notas'),
                  _buildWarningItem('Tu historial de progreso'),
                  _buildWarningItem('Tus preferencias'),
                  _buildWarningItem('Datos sincronizados en la nube'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirmation instruction
            Text(
              'Para confirmar, escribe "$_confirmationWord" a continuacion:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),

            // Confirmation text field
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _confirmationWord,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.error,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.keyboard,
                  color: _canDelete ? colorScheme.error : Colors.grey,
                ),
                suffixIcon: _canDelete
                    ? Icon(
                        Icons.check_circle,
                        color: colorScheme.error,
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !_isLoading,
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),

        // Delete button
        FilledButton(
          onPressed: _canDelete && !_isLoading ? _deleteAccount : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onError,
                  ),
                )
              : const Text('Eliminar Cuenta'),
        ),
      ],
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '- ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
