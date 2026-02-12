import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/update_info.dart';
import 'error_handler.dart';
import 'logger_service.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return RemoteConfigService(errorHandler);
});

/// Service for managing Firebase Remote Config
/// Handles version checking and forced update logic
class RemoteConfigService {
  final ErrorHandler _errorHandler;
  final LoggerService _logger = LoggerService();
  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;
  bool _firebaseAvailable = false;

  RemoteConfigService(this._errorHandler);

  /// Initialize Firebase Remote Config with default values
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _firebaseAvailable = Firebase.apps.isNotEmpty;
      if (!_firebaseAvailable) {
        _logger.debug('Service', '[RemoteConfig] Firebase no disponible - omitiendo');
        _initialized = true;
        return;
      }

      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure Remote Config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults({
        'min_version': '1.0.0',
        'latest_version': '1.0.0',
        'force_update': false,
        'update_message_es': 'Hay una nueva versión disponible.',
        'update_url_android':
            'https://play.google.com/store/apps/details?id=com.example.checklistApp',
        'update_url_ios':
            'https://apps.apple.com/app/id123456789', // Replace with actual App Store ID
        'update_url_windows':
            'https://www.microsoft.com/store/apps/123456789', // Replace with actual Microsoft Store ID
      });

      // Fetch and activate latest config
      await _fetchAndActivate();

      _initialized = true;
      _logger.debug('Service', '[RemoteConfig] Inicializado correctamente');
    } catch (e, stack) {
      _logger.debug('Service', '[RemoteConfig] Error al inicializar: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.warning,
        message: 'Error al inicializar Remote Config',
        userMessage: 'No se pudo verificar actualizaciones',
        stackTrace: stack,
      );
      _initialized = true; // Mark as initialized to prevent retry loops
    }
  }

  /// Fetch and activate remote config values
  Future<bool> _fetchAndActivate() async {
    if (_remoteConfig == null) return false;

    try {
      final activated = await _remoteConfig!.fetchAndActivate();
      if (activated) {
        _logger.debug('Service', '[RemoteConfig] Configuración actualizada desde servidor');
      } else {
        _logger.debug('Service', '[RemoteConfig] Usando configuración en cache (sin cambios)');
      }
      return activated;
    } catch (e) {
      _logger.debug('Service', '[RemoteConfig] Error al obtener configuración: $e');
      // Continue with cached/default values
      return false;
    }
  }

  /// Check for updates and return update information
  Future<UpdateInfo?> checkForUpdates() async {
    if (!_initialized) {
      await initialize();
    }

    if (!_firebaseAvailable || _remoteConfig == null) {
      _logger.debug('Service', '[RemoteConfig] Firebase no disponible - omitiendo check');
      return null;
    }

    try {
      // Refresh config (respects minimum fetch interval)
      await _fetchAndActivate();

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Get remote config values
      final minVersion = _remoteConfig!.getString('min_version');
      final latestVersion = _remoteConfig!.getString('latest_version');
      final forceUpdate = _remoteConfig!.getBool('force_update');
      final updateMessage = _remoteConfig!.getString('update_message_es');

      // Build platform-specific URLs
      final platformUrls = <String, String>{
        'android': _remoteConfig!.getString('update_url_android'),
        'ios': _remoteConfig!.getString('update_url_ios'),
        'windows': _remoteConfig!.getString('update_url_windows'),
      };

      final updateInfo = UpdateInfo(
        minVersion: minVersion,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        forceUpdate: forceUpdate,
        updateMessage: updateMessage.isNotEmpty ? updateMessage : null,
        platformUrls: platformUrls,
      );

      _logger.debug('Service', '[RemoteConfig] $updateInfo');

      return updateInfo;
    } catch (e, stack) {
      _logger.debug('Service', '[RemoteConfig] Error al verificar actualizaciones: $e');
      _errorHandler.handle(
        e,
        type: ErrorType.network,
        severity: ErrorSeverity.info,
        message: 'Error al verificar actualizaciones',
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get the current platform name
  String getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    }
    return 'unknown';
  }

  /// Get a string value from remote config
  String getString(String key) {
    if (_remoteConfig == null) return '';
    return _remoteConfig!.getString(key);
  }

  /// Get a boolean value from remote config
  bool getBool(String key) {
    if (_remoteConfig == null) return false;
    return _remoteConfig!.getBool(key);
  }

  /// Get an integer value from remote config
  int getInt(String key) {
    if (_remoteConfig == null) return 0;
    return _remoteConfig!.getInt(key);
  }

  /// Get a double value from remote config
  double getDouble(String key) {
    if (_remoteConfig == null) return 0.0;
    return _remoteConfig!.getDouble(key);
  }

  /// Check if Remote Config is available
  bool get isAvailable => _firebaseAvailable && _initialized;
}
