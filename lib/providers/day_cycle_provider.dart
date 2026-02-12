import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:checklist_app/services/day_cycle_service.dart';

/// Provider para el servicio de ciclo del dia.
final dayCycleServiceProvider = Provider<DayCycleService>((ref) {
  final service = DayCycleService.instance;
  service.startMonitoring();

  ref.onDispose(() {
    service.stopMonitoring();
  });

  return service;
});

/// Provider que retorna el periodo actual del dia.
///
/// Se actualiza automaticamente cuando cambia el periodo.
final currentTimePeriodProvider =
    StreamProvider.autoDispose<TimePeriod>((ref) {
  final service = ref.watch(dayCycleServiceProvider);

  // Emitir el periodo actual inmediatamente, luego escuchar cambios
  final controller = StreamController<TimePeriod>();

  // Agregar el periodo actual primero
  controller.add(service.getCurrentPeriod());

  // Escuchar cambios futuros
  final subscription = service.periodStream.listen(controller.add);

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider que indica si se debe mostrar el mensaje de despedida.
///
/// Retorna true si:
/// - Es hora de la noche (22:00 - 4:59) o atardecer (18:00 - 21:59)
/// - No se ha mostrado el mensaje de despedida hoy
final shouldShowFarewellProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(dayCycleServiceProvider);
  final currentPeriod = service.getCurrentPeriod();

  // Solo mostrar en atardecer o noche
  if (currentPeriod != TimePeriod.evening && currentPeriod != TimePeriod.night) {
    return false;
  }

  return await service.shouldShowFarewell();
});

/// Provider para marcar el mensaje de despedida como mostrado.
///
/// Uso:
/// ```dart
/// ref.read(markFarewellShownProvider)();
/// ```
final markFarewellShownProvider = Provider<Future<void> Function()>((ref) {
  final service = ref.watch(dayCycleServiceProvider);
  return service.markFarewellShown;
});

/// Provider que emite eventos cuando se debe mostrar el mensaje de despedida.
///
/// Escucha las transiciones de evening a night para activar el mensaje.
final farewellTriggerProvider = StreamProvider.autoDispose<void>((ref) {
  final service = ref.watch(dayCycleServiceProvider);
  return service.farewellTriggerStream;
});

/// Notifier para gestionar el estado de visibilidad del mensaje de despedida.
class FarewellVisibilityNotifier extends StateNotifier<bool> {
  final Ref _ref;

  FarewellVisibilityNotifier(this._ref) : super(false);

  /// Muestra el mensaje de despedida si las condiciones lo permiten.
  Future<void> showIfAllowed() async {
    final service = _ref.read(dayCycleServiceProvider);
    final shouldShow = await service.shouldShowFarewell();

    if (shouldShow) {
      state = true;
    }
  }

  /// Oculta el mensaje de despedida y lo marca como mostrado.
  Future<void> dismiss() async {
    state = false;
    await _ref.read(markFarewellShownProvider)();
  }

  /// Muestra el mensaje de despedida forzadamente (para testing).
  void forceShow() {
    state = true;
  }
}

/// Provider para gestionar la visibilidad del mensaje de despedida.
final farewellVisibilityProvider =
    StateNotifierProvider.autoDispose<FarewellVisibilityNotifier, bool>((ref) {
  return FarewellVisibilityNotifier(ref);
});
