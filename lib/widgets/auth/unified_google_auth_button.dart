import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_manager.dart';

/// Unified Google authentication button
/// Automatically detects if it's login or register
/// Handles profile verification and sync activation
class UnifiedGoogleAuthButton extends ConsumerStatefulWidget {
  final bool requireTermsAcceptance;
  final VoidCallback? onSuccess;
  final String? customLabel;
  final ButtonStyle? style;
  final bool showIcon;

  const UnifiedGoogleAuthButton({
    this.requireTermsAcceptance = false,
    this.onSuccess,
    this.customLabel,
    this.style,
    this.showIcon = true,
    super.key,
  });

  @override
  ConsumerState<UnifiedGoogleAuthButton> createState() =>
      _UnifiedGoogleAuthButtonState();
}

class _UnifiedGoogleAuthButtonState
    extends ConsumerState<UnifiedGoogleAuthButton> {
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);

    try {
      final authManager = ref.read(authManagerProvider);
      final (:isNewUser, :result) = await authManager.authenticateWithGoogle(
        requireTermsAcceptance: widget.requireTermsAcceptance,
      );

      if (!mounted) return;

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isNewUser
                    ? 'Cuenta creada con Google exitosamente'
                    : 'Bienvenido de vuelta!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Call success callback
        widget.onSuccess?.call();
      } else if (result.cancelled) {
        // User cancelled, do nothing
      } else if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = ref.watch(authManagerProvider);
    final isAnonymous = authManager.currentUser?.isAnonymous ?? true;

    final defaultLabel = isAnonymous
        ? 'Vincular con Google'
        : 'Iniciar sesión con Google';

    if (widget.showIcon) {
      return OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleAuth,
        style: widget.style,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata, size: 24),
              ),
        label: Text(widget.customLabel ?? defaultLabel),
      );
    }

    return OutlinedButton(
      onPressed: _isLoading ? null : _handleAuth,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.customLabel ?? defaultLabel),
    );
  }
}
