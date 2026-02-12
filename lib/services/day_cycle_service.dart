import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Periodos del dia para el ciclo diario.
enum TimePeriod {
  morning, // 5:00 - 11:59
  afternoon, // 12:00 - 17:59
  evening, // 18:00 - 21:59
  night, // 22:00 - 4:59
}

/// Servicio singleton para detectar el ciclo del dia y transiciones.
///
/// Detecta cuando el usuario transita de la tarde/noche al periodo nocturno,
/// lo cual activa el mensaje de despedida del guia.
class DayCycleService {
  DayCycleService._();
  static final instance = DayCycleService._();

  static const _keyLastFarewellDate = 'last_farewell_date';

  Timer? _checkTimer;
  TimePeriod? _lastKnownPeriod;

  final _periodController = StreamController<TimePeriod>.broadcast();
  final _farewellTriggerController = StreamController<void>.broadcast();

  /// Stream del periodo actual del dia.
  Stream<TimePeriod> get periodStream => _periodController.stream;

  /// Stream que emite cuando se debe mostrar el mensaje de despedida.
  Stream<void> get farewellTriggerStream => _farewellTriggerController.stream;

  /// Obtiene el periodo actual basado en la hora.
  TimePeriod getCurrentPeriod() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return TimePeriod.morning;
    } else if (hour >= 12 && hour < 18) {
      return TimePeriod.afternoon;
    } else if (hour >= 18 && hour < 22) {
      return TimePeriod.evening;
    } else {
      return TimePeriod.night;
    }
  }

  /// Inicia el monitoreo del ciclo del dia.
  ///
  /// Verifica cada minuto si ha habido una transicion de periodo.
  void startMonitoring() {
    _lastKnownPeriod = getCurrentPeriod();
    _periodController.add(_lastKnownPeriod!);

    // Verificar cada minuto
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkPeriodTransition(),
    );
  }

  /// Detiene el monitoreo del ciclo del dia.
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Verifica si hubo una transicion de periodo.
  Future<void> _checkPeriodTransition() async {
    final currentPeriod = getCurrentPeriod();

    if (_lastKnownPeriod != currentPeriod) {
      final previousPeriod = _lastKnownPeriod;
      _lastKnownPeriod = currentPeriod;
      _periodController.add(currentPeriod);

      // Detectar transicion de evening a night (fin del dia)
      if (previousPeriod == TimePeriod.evening &&
          currentPeriod == TimePeriod.night) {
        await _handleEndOfDayTransition();
      }
    }
  }

  /// Maneja la transicion de fin de dia.
  Future<void> _handleEndOfDayTransition() async {
    final shouldShow = await shouldShowFarewell();
    if (shouldShow) {
      _farewellTriggerController.add(null);
    }
  }

  /// Verifica si se debe mostrar el mensaje de despedida hoy.
  ///
  /// Retorna true si no se ha mostrado hoy, false si ya se mostro.
  Future<bool> shouldShowFarewell() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastFarewellDate);

    if (lastDateStr == null) {
      return true;
    }

    final lastDate = DateTime.tryParse(lastDateStr);
    if (lastDate == null) {
      return true;
    }

    final today = DateTime.now();
    final isSameDay = lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;

    return !isSameDay;
  }

  /// Marca el mensaje de despedida como mostrado para hoy.
  Future<void> markFarewellShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    await prefs.setString(_keyLastFarewellDate, today);
  }

  /// Fuerza la verificacion de despedida (util para testing o triggers manuales).
  Future<void> checkAndTriggerFarewell() async {
    final currentPeriod = getCurrentPeriod();
    if (currentPeriod == TimePeriod.night || currentPeriod == TimePeriod.evening) {
      final shouldShow = await shouldShowFarewell();
      if (shouldShow) {
        _farewellTriggerController.add(null);
      }
    }
  }

  /// Obtiene el nombre localizado del periodo actual.
  String getPeriodName(TimePeriod period) {
    switch (period) {
      case TimePeriod.morning:
        return 'Manana';
      case TimePeriod.afternoon:
        return 'Tarde';
      case TimePeriod.evening:
        return 'Atardecer';
      case TimePeriod.night:
        return 'Noche';
    }
  }

  /// Libera recursos del servicio.
  void dispose() {
    _checkTimer?.cancel();
    _periodController.close();
    _farewellTriggerController.close();
  }
}
