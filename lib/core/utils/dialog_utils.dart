import 'package:flutter/material.dart';

class DialogUtils {
  /// Show a snackbar with optional error styling and undo action
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isUndo = false,
    VoidCallback? onUndo,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : null,
        duration: Duration(seconds: isUndo ? 4 : 2),
        action: isUndo && onUndo != null
            ? SnackBarAction(
                label: 'Deshacer',
                textColor: Colors.white,
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  /// Build an error message container
  static Widget buildErrorContainer(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Validate task title
  static String? validateTaskTitle(String title) {
    if (title.trim().isEmpty) {
      return 'El título es obligatorio';
    }
    if (title.trim().length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    return null;
  }
}
