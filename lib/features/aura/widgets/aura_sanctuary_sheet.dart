import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aura_provider.dart';

/// Modal del Santuario de Aura (Tienda y Canje de Recompensas)
class AuraSanctuarySheet extends ConsumerWidget {
  const AuraSanctuarySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuraSanctuarySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auraState = ref.watch(auraStateProvider);
    final auraService = ref.read(auraServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header con saldo de Aura
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          auraState.rank.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Santuario de Aura',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${auraState.rank.title} • Nivel ${auraState.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${auraState.availablePoints} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Contenido con scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Escudo de Racha
                _ShopItemCard(
                  icon: Icons.shield_rounded,
                  iconColor: Colors.blueAccent,
                  title: 'Escudo de Racha',
                  description: 'Protege tu racha diaria si no puedes completar tareas un día.',
                  cost: 100,
                  currentQuantity: auraState.streakShields,
                  quantityLabel: '${auraState.streakShields} activos',
                  canAfford: auraState.availablePoints >= 100,
                  onBuy: () async {
                    final success = await auraService.buyStreakShield();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '¡Escudo de Racha adquirido con éxito! 🛡️'
                                : 'No tienes suficientes puntos de Aura.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Temas Cósmicos Desbloqueables
                Text(
                  'Temas Cósmicos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),

                _ThemeUnlockCard(
                  themeId: 'cosmic_purple',
                  themeName: 'Nebulosa Púrpura',
                  gradient: const [Color(0xFF6B21A8), Color(0xFFA855F7)],
                  cost: 300,
                  isUnlocked: auraState.unlockedThemes.contains('cosmic_purple'),
                  canAfford: auraState.availablePoints >= 300,
                  onUnlock: () => auraService.unlockTheme(
                    'cosmic_purple',
                    cost: 300,
                    themeName: 'Nebulosa Púrpura',
                  ),
                ),
                const SizedBox(height: 12),

                _ThemeUnlockCard(
                  themeId: 'aurora_borealis',
                  themeName: 'Aurora Boreal',
                  gradient: const [Color(0xFF0F766E), Color(0xFF10B981)],
                  cost: 600,
                  isUnlocked: auraState.unlockedThemes.contains('aurora_borealis'),
                  canAfford: auraState.availablePoints >= 600,
                  onUnlock: () => auraService.unlockTheme(
                    'aurora_borealis',
                    cost: 600,
                    themeName: 'Aurora Boreal',
                  ),
                ),
                const SizedBox(height: 12),

                _ThemeUnlockCard(
                  themeId: 'solar_gold',
                  themeName: 'Oro Solar',
                  gradient: const [Color(0xFFB45309), Color(0xFFF59E0B)],
                  cost: 1200,
                  isUnlocked: auraState.unlockedThemes.contains('solar_gold'),
                  canAfford: auraState.availablePoints >= 1200,
                  onUnlock: () => auraService.unlockTheme(
                    'solar_gold',
                    cost: 1200,
                    themeName: 'Oro Solar',
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Historial Reciente de Aura
                Text(
                  'Actividad Reciente',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: auraState.recentActivity.map((activity) {
                      final isPositive = activity.contains('+');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                              size: 16,
                              color: isPositive ? Colors.green : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activity,
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final int cost;
  final int currentQuantity;
  final String quantityLabel;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cost,
    required this.currentQuantity,
    required this.quantityLabel,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quantityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canAfford ? onBuy : null,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                Text('$cost'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeUnlockCard extends StatelessWidget {
  final String themeId;
  final String themeName;
  final List<Color> gradient;
  final int cost;
  final bool isUnlocked;
  final bool canAfford;
  final VoidCallback onUnlock;

  const _ThemeUnlockCard({
    required this.themeId,
    required this.themeName,
    required this.gradient,
    required this.cost,
    required this.isUnlocked,
    required this.canAfford,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? Colors.green.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              themeName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isUnlocked)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Desbloqueado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: canAfford ? onUnlock : null,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
                  Text('$cost pts'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
