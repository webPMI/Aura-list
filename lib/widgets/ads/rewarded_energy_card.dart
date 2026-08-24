import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ad_provider.dart';
import '../../features/aura/providers/aura_provider.dart';
import '../../services/ads/ad_service.dart';
import '../../core/constants/ad_constants.dart';

/// Tarjeta voluntaria de anuncio recompensado para ganar puntos de energía Aura
class RewardedEnergyCard extends ConsumerStatefulWidget {
  final VoidCallback? onEnergyEarned;

  const RewardedEnergyCard({
    super.key,
    this.onEnergyEarned,
  });

  @override
  ConsumerState<RewardedEnergyCard> createState() => _RewardedEnergyCardState();
}

class _RewardedEnergyCardState extends ConsumerState<RewardedEnergyCard> {
  bool _isLoading = false;

  Future<void> _handleWatchAd() async {
    setState(() => _isLoading = true);

    final adService = ref.read(adServiceProvider);
    final status = await adService.showRewardedAd(
      onRewardEarned: () {
        ref.read(remainingRewardedAdsProvider.notifier).state =
            (AdConstants.maxRewardedAdsPerDay - adService.rewardedAdsWatchedToday).clamp(0, AdConstants.maxRewardedAdsPerDay);

        // Sumar puntos en el sistema de Aura
        ref.read(auraServiceProvider).addPoints(
          AdConstants.rewardEnergyPoints,
          reason: 'Recarga voluntaria de energía',
        );

        if (widget.onEnergyEarned != null) {
          widget.onEnergyEarned!();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('¡+${AdConstants.rewardEnergyPoints} de Energía Aura desbloqueada!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.indigo.shade900,
            ),
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (status == RewardedAdStatus.notAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has alcanzado el límite diario de recompensas. ¡Vuelve mañana!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remaining = ref.watch(remainingRewardedAdsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.7),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.amber,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recarga de Energía Aura',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mira un anuncio corto para ganar +${AdConstants.rewardEnergyPoints} pts ($remaining disponibles hoy)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: (_isLoading || remaining <= 0) ? null : _handleWatchAd,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_circle_outline_rounded, size: 16),
            label: Text(remaining > 0 ? 'Ver' : 'Listo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
