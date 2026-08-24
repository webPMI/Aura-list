import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ads/ad_service.dart';
import '../core/constants/ad_constants.dart';

/// Provider singleton de AdService
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  service.initialize();
  return service;
});

/// Estado de usuario Pro (sin anuncios)
final isProUserProvider = StateProvider<bool>((ref) => false);

/// Anuncios recompensados disponibles hoy
final remainingRewardedAdsProvider = StateProvider<int>((ref) {
  final adService = ref.watch(adServiceProvider);
  final remaining = AdConstants.maxRewardedAdsPerDay - adService.rewardedAdsWatchedToday;
  return remaining.clamp(0, AdConstants.maxRewardedAdsPerDay);
});
