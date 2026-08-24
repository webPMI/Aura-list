import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/aura_state.dart';
import '../../../services/logger_service.dart';

/// Servicio para la gestión persistente del Aura
class AuraService extends ChangeNotifier {
  static const String _prefKey = 'aura_state_v1';
  final LoggerService _logger = LoggerService();

  AuraState _state = const AuraState();
  bool _isLoaded = false;

  AuraState get state => _state;
  bool get isLoaded => _isLoaded;

  /// Carga el estado del Aura desde el almacenamiento local
  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _state = AuraState.fromJson(jsonString);
      }
      _isLoaded = true;
      notifyListeners();
      _logger.info('AuraService', 'Estado de Aura cargado: ${_state.availablePoints} pts disponibles, Nivel ${_state.level}');
    } catch (e) {
      _logger.error('AuraService', 'Error al cargar AuraState', error: e);
      _isLoaded = true;
    }
  }

  /// Guarda el estado actual
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _state.toJson());
    } catch (e) {
      _logger.error('AuraService', 'Error al guardar AuraState', error: e);
    }
  }

  /// Suma puntos de Aura por una acción
  Future<void> addPoints(int amount, {required String reason}) async {
    if (amount <= 0) return;

    final updatedRecent = [
      '$reason (+$amount pts)',
      ..._state.recentActivity.take(9),
    ];

    _state = _state.copyWith(
      totalPoints: _state.totalPoints + amount,
      availablePoints: _state.availablePoints + amount,
      recentActivity: updatedRecent,
    );

    notifyListeners();
    await _save();
    _logger.info('AuraService', '+$amount pts de Aura añadidos por: $reason. Total: ${_state.availablePoints}');
  }

  /// Canjea/gasta puntos de Aura
  Future<bool> spendPoints(int amount, {required String reason}) async {
    if (amount <= 0 || _state.availablePoints < amount) {
      return false;
    }

    final updatedRecent = [
      '$reason (-$amount pts)',
      ..._state.recentActivity.take(9),
    ];

    _state = _state.copyWith(
      availablePoints: _state.availablePoints - amount,
      recentActivity: updatedRecent,
    );

    notifyListeners();
    await _save();
    _logger.info('AuraService', '-$amount pts de Aura canjeados por: $reason');
    return true;
  }

  /// Compra un Escudo de Racha (100 pts)
  Future<bool> buyStreakShield({int cost = 100}) async {
    if (_state.availablePoints < cost) return false;

    final updatedRecent = [
      'Escudo de Racha adquirido (-$cost pts)',
      ..._state.recentActivity.take(9),
    ];

    _state = _state.copyWith(
      availablePoints: _state.availablePoints - cost,
      streakShields: _state.streakShields + 1,
      recentActivity: updatedRecent,
    );

    notifyListeners();
    await _save();
    return true;
  }

  /// Desbloquea un tema cósmico
  Future<bool> unlockTheme(String themeId, {required int cost, required String themeName}) async {
    if (_state.unlockedThemes.contains(themeId)) return true;
    if (_state.availablePoints < cost) return false;

    final updatedRecent = [
      'Tema "$themeName" desbloqueado (-$cost pts)',
      ..._state.recentActivity.take(9),
    ];

    _state = _state.copyWith(
      availablePoints: _state.availablePoints - cost,
      unlockedThemes: [..._state.unlockedThemes, themeId],
      recentActivity: updatedRecent,
    );

    notifyListeners();
    await _save();
    return true;
  }
}
