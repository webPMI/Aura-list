import 'package:flutter/foundation.dart';

/// Constantes y configuraciones de monetización y anuncios para AuraList
class AdConstants {
  // Flag global para activar/desactivar anuncios
  static const bool adsEnabled = true;

  // --- GOOGLE ADMOB TEST IDs (Oficiales de Google) ---
  // Android Test IDs
  static const String androidBannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewardedTestId = 'ca-app-pub-3940256099942544/5224354917';

  // iOS Test IDs
  static const String iosBannerTestId = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialTestId = 'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewardedTestId = 'ca-app-pub-3940256099942544/1712485313';

  // --- PRODUCCIÓN (IDs reales de Google AdMob) ---
  static const String androidAppId = 'ca-app-pub-1988580228487420~1721010813';
  static const String androidNativeAdUnitId = 'ca-app-pub-1988580228487420/6207050735';
  static const String androidBannerProdId = 'ca-app-pub-1988580228487420/6207050735';
  static const String androidRewardedProdId = '';
  static const String iosBannerProdId = '';
  static const String iosRewardedProdId = '';

  // --- GOOGLE ADSENSE (Para versión Web) ---
  static const String adSensePublisherId = 'ca-pub-1988580228487420';
  static const String adSenseSlotId = 'xxxxxxxxxx';

  /// Obtiene el ID del Banner según la plataforma y el entorno
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosBannerTestId
          : androidBannerTestId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosBannerProdId.isNotEmpty ? iosBannerProdId : iosBannerTestId;
    }
    return androidBannerProdId.isNotEmpty ? androidBannerProdId : androidBannerTestId;
  }

  /// Obtiene el ID del Anuncio Recompensado según la plataforma
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosRewardedTestId
          : androidRewardedTestId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return iosRewardedProdId.isNotEmpty ? iosRewardedProdId : iosRewardedTestId;
    }
    return androidRewardedProdId.isNotEmpty ? androidRewardedProdId : androidRewardedTestId;
  }

  // Límites para evitar saturación (anti-spam)
  static const int minMinutesBetweenInterstitials = 10;
  static const int maxRewardedAdsPerDay = 5;
  static const int rewardEnergyPoints = 25; // Puntos de aura/energía por video voluntario
}
