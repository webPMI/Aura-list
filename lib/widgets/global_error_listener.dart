import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_handler.dart';

class GlobalErrorListener extends ConsumerWidget {
  final Widget child;

  const GlobalErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to error stream
    ref.listen<AsyncValue<AppError>>(errorStreamProvider, (previous, next) {
      if (next is AsyncData<AppError>) {
        final error = next.value;
        _showErrorUI(context, error);
      }
    });

    return child;
  }

  void _showErrorUI(BuildContext context, AppError error) {
    final colorScheme = Theme.of(context).colorScheme;

    if (error.severity == ErrorSeverity.critical) {
      _showErrorDialog(context, error, colorScheme);
    } else if (error.severity == ErrorSeverity.error ||
        error.severity == ErrorSeverity.warning) {
      _showErrorSnackBar(context, error, colorScheme);
    }
  }

  void _showErrorSnackBar(
    BuildContext context,
    AppError error,
    ColorScheme colorScheme,
  ) {
    final isError = error.severity == ErrorSeverity.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.warning_amber_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.displayMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? colorScheme.error : Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        action: error.onAction != null
            ? SnackBarAction(
                label: error.actionLabel ?? 'REINTENTAR',
                textColor: Colors.white,
                onPressed: error.onAction!,
              )
            : null,
      ),
    );
  }

  void _showErrorDialog(
    BuildContext context,
    AppError error,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem, color: colorScheme.error),
            const SizedBox(width: 12),
            const Text('Error Crítico'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.displayMessage),
            const SizedBox(height: 16),
            const Text(
              'Por favor, reinicia la aplicación o contacta con soporte si el error persiste.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          if (error.onAction != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                error.onAction!();
              },
              child: Text(error.actionLabel ?? 'REINTENTAR'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}
