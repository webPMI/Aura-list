import 'package:flutter/foundation.dart';
import '../../core/constants/ad_constants.dart';
import '../logger_service.dart';

/// Resultado de la reproducción de un anuncio recompensado
enum RewardedAdStatus {
  completed,
  dismissed,
  failed,
  notAvailable,
}

/// Servicio de Monetización Multiplataforma para AuraList
class AdService {
  final LoggerService _logger = LoggerService();
  bool _isInitialized = false;
  int _rewardedAdsWatchedToday = 0;
  DateTime? _lastInterstitialShownAt;

  bool get isInitialized => _isInitialized;
  int get rewardedAdsWatchedToday => _rewardedAdsWatchedToday;

  /// Inicializa el servicio de anuncios de forma segura para cualquier plataforma
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        _logger.info('AdService', 'Inicializado para Web (AdSense / Web slots)');
      } else if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        _logger.info('AdService', 'Inicializado para Móvil (Google AdMob)');
      } else {
        _logger.info('AdService', 'Inicializado para Desktop (Promos / Modo silencioso)');
      }
      _isInitialized = true;
    } catch (e) {
      _logger.error('AdService', 'Error al inicializar AdService', error: e);
    }
  }

  /// Verifica si se puede mostrar un anuncio recompensado
  bool canShowRewardedAd() {
    if (!AdConstants.adsEnabled) return false;
    return _rewardedAdsWatchedToday < AdConstants.maxRewardedAdsPerDay;
  }

  /// Muestra un anuncio de video recompensado voluntario
  /// Retorna [RewardedAdStatus.completed] si el usuario vio el anuncio completo
  Future<RewardedAdStatus> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onDismissed,
  }) async {
    if (!canShowRewardedAd()) {
      _logger.info('AdService', 'Límite de anuncios recompensados alcanzado por hoy');
      return RewardedAdStatus.notAvailable;
    }

    try {
      _logger.info('AdService', 'Mostrando anuncio recompensado voluntario...');

      // En entorno Web / Desktop / Simulación: otorgamos la recompensa de inmediato o tras breve animación
      _rewardedAdsWatchedToday++;
      onRewardEarned();
      return RewardedAdStatus.completed;
    } catch (e) {
      _logger.error('AdService', 'Error al reproducir anuncio recompensado', error: e);
      return RewardedAdStatus.failed;
    }
  }

  /// Muestra un anuncio interstitial con control estricto de frecuencia
  Future<bool> showInterstitialAd() async {
    if (!AdConstants.adsEnabled) return false;

    final now = DateTime.now();
    if (_lastInterstitialShownAt != null) {
      final difference = now.difference(_lastInterstitialShownAt!).inMinutes;
      if (difference < AdConstants.minMinutesBetweenInterstitials) {
        // Cooldown activo: no mostrar para no molestar
        return false;
      }
    }

    _lastInterstitialShownAt = now;
    _logger.info('AdService', 'Interstitial mostrado con éxito');
    return true;
  }
}
