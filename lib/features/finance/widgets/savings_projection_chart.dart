import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_projection.dart';

/// Gráfico de proyección de ahorro/inversión dibujado con CustomPainter.
///
/// Muestra la evolución del saldo (línea) frente a los aportes acumulados
/// (área gris) a lo largo del horizonte simulado.
class SavingsProjectionChart extends StatelessWidget {
  final SavingsProjection projection;

  const SavingsProjectionChart({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'es_ES');

    if (projection.points.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sin datos de proyección',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una cuenta de ahorro para ver su crecimiento proyectado',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final last = projection.points.last;
    final crossover = projection.points.indexWhere(
      (p) => p.interest >= p.contributions,
    );

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Simulación de crecimiento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Interés compuesto mensual · ${projection.annualInterestRate.toStringAsFixed(2)}% anual',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _ProjectionPainter(
                  projection: projection,
                  lineColor: theme.colorScheme.primary,
                  contributionsColor: Colors.grey,
                  gridColor: theme.dividerColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _LegendChip(
                  color: theme.colorScheme.primary,
                  label: 'Saldo proyectado',
                ),
                _LegendChip(color: Colors.grey, label: 'Aportes acumulados'),
                _LegendChip(color: Colors.orange, label: 'Interés generado'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Horizonte',
                    value: '${projection.monthCount ~/ 12} años',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Total aportado',
                    value: currencyFormat.format(last.contributions),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Interés generado',
                    value: currencyFormat.format(last.interest),
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insights,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      crossover >= 0
                          ? 'El interés compuesto supera a tus aportes en ~${crossover ~/ 12} años y ${crossover % 12} meses. A partir de ahí tu dinero crece por sí solo.'
                          : 'Saldo final proyectado: ${currencyFormat.format(last.balance)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
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
}

class _ProjectionPainter extends CustomPainter {
  final SavingsProjection projection;
  final Color lineColor;
  final Color contributionsColor;
  final Color gridColor;

  _ProjectionPainter({
    required this.projection,
    required this.lineColor,
    required this.contributionsColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = projection.points;
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const horizontalGridCount = 4;
    for (var i = 0; i <= horizontalGridCount; i++) {
      final y = (size.height * i / horizontalGridCount).toDouble();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double clamp01(double v) => v.clamp(0.0, 1.0);
    double xFor(int index) => (index / (points.length - 1)) * size.width;
    double yFor(double value, double maxValue) =>
        size.height - clamp01(value / maxValue) * size.height * 0.92 - 4;

    final maxBalance = points.map((p) => p.balance).reduce(math.max);
    final maxContrib = points.last.contributions;
    final maxValue = math.max(maxBalance, maxContrib);

    // Área de aportes acumulados.
    final contributionsPath = Path()..moveTo(0, size.height);
    for (var i = 0; i < points.length; i++) {
      contributionsPath.lineTo(
        xFor(i),
        yFor(points[i].contributions, maxValue),
      );
    }
    contributionsPath.lineTo(size.width, size.height);
    contributionsPath.close();

    canvas.drawPath(
      contributionsPath,
      Paint()
        ..color = contributionsColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // Línea de saldo proyectado.
    final balancePath = Path()..moveTo(0, yFor(points.first.balance, maxValue));
    for (var i = 1; i < points.length; i++) {
      balancePath.lineTo(xFor(i), yFor(points[i].balance, maxValue));
    }

    canvas.drawPath(
      balancePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Punto final de la línea de saldo.
    final last = points.last;
    canvas.drawCircle(
      Offset(xFor(points.length - 1), yFor(last.balance, maxValue)),
      4,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter oldDelegate) {
    return oldDelegate.projection != projection ||
        oldDelegate.lineColor != lineColor;
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
