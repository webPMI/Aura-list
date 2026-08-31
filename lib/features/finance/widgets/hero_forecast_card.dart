import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarjeta Hero premium reutilizable con gradiente para mostrar el balance actual,
/// compromisos fijos mensuales y total de pagos del horizonte temporal.
class HeroForecastCard extends StatelessWidget {
  final double currentBalance;
  final double monthlyFixedCommitments;
  final double horizonExpenses;
  final int horizonMonths;
  final String title;
  final VoidCallback? onTap;

  const HeroForecastCard({
    super.key,
    required this.currentBalance,
    required this.monthlyFixedCommitments,
    required this.horizonExpenses,
    required this.horizonMonths,
    this.title = 'Balance Disponible Actual',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_ES');
    final isPositive = currentBalance >= 0;

    final content = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [const Color(0xFF8E0E00), const Color(0xFF1F1C18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Horizonte: $horizonMonths ${horizonMonths == 1 ? 'Mes' : 'Meses'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(currentBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compromiso Fijo / Mes',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(monthlyFixedCommitments),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pagos en $horizonMonths ${horizonMonths == 1 ? 'mes' : 'm.'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(horizonExpenses),
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
