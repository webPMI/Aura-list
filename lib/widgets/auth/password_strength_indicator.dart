import 'package:flutter/material.dart';

/// Indicador visual de fortaleza de contrasena
/// Muestra una barra de progreso con colores segun la fortaleza
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  /// Calcula la fortaleza de la contrasena (0-4)
  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Longitud
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;

    // Tiene mayusculas
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;

    // Tiene numeros
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;

    // Tiene caracteres especiales
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    return strength > 4 ? 4 : strength;
  }

  /// Retorna el color segun la fortaleza
  Color _getColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Retorna el texto descriptivo de la fortaleza
  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Muy debil';
      case 2:
        return 'Debil';
      case 3:
        return 'Buena';
      case 4:
        return 'Fuerte';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 4,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  color: _getColor(strength),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getColor(strength),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRequirements(),
      ],
    );
  }

  Widget _buildRequirements() {
    final hasLength = password.length >= 6;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementItem(
          text: 'Al menos 6 caracteres',
          isMet: hasLength,
        ),
        _RequirementItem(
          text: 'Al menos una mayuscula',
          isMet: hasUppercase,
        ),
        _RequirementItem(
          text: 'Al menos un numero',
          isMet: hasNumber,
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _RequirementItem({
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet
                  ? Colors.green
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
