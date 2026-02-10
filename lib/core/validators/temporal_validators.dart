/// Validadores para objetos temporales y reglas de recurrencia en AuraList.
///
/// Este modulo proporciona clases de validacion para:
/// - [RecurrenceRuleValidator]: Validacion completa de reglas de recurrencia
/// - [DateRangeValidator]: Validacion de rangos de fechas
///
/// Todos los validadores lanzan excepciones especificas de [temporal_exceptions.dart]
/// con mensajes en espanol para mantener consistencia con la localizacion de la app.
///
/// Ejemplo de uso:
/// ```dart
/// final rule = RecurrenceRule(
///   frequency: RecurrenceFrequency.weekly,
///   interval: 2,
///   byDays: [WeekDay.monday, WeekDay.wednesday],
///   startDate: DateTime.now(),
/// );
///
/// // Validacion completa
/// RecurrenceRuleValidator.validate(rule);
///
/// // Validacion de rango de fechas
/// DateRangeValidator.validate(startDate, endDate);
/// ```
library;

import '../../models/recurrence_rule.dart';
import '../exceptions/temporal_exceptions.dart';

// =============================================================================
// RECURRENCE RULE VALIDATOR
// =============================================================================

/// Validador para objetos [RecurrenceRule].
///
/// Proporciona metodos estaticos para validar todos los aspectos de una regla
/// de recurrencia, incluyendo frecuencia, intervalo, dias, meses, y rangos de fechas.
///
/// Todas las validaciones lanzan [InvalidRecurrenceRuleException] con mensajes
/// descriptivos en espanol cuando encuentran datos invalidos.
class RecurrenceRuleValidator {
  // Constantes de validacion
  static const int _minInterval = 1;
  static const int _maxInterval = 365;
  static const int _minMonthDay = -31;
  static const int _maxMonthDay = 31;
  static const int _minMonth = 1;
  static const int _maxMonth = 12;
  static const int _minWeekPosition = -5;
  static const int _maxWeekPosition = 5;

  /// Valida completamente una regla de recurrencia.
  ///
  /// Ejecuta todas las validaciones disponibles:
  /// - Intervalo dentro de rango permitido
  /// - Frecuencia y sus reglas especificas
  /// - Dias de la semana apropiados para la frecuencia
  /// - Dias del mes validos
  /// - Meses validos
  /// - Posicion de semana valida
  /// - Rango de fechas valido
  /// - Conteo de ocurrencias valido
  ///
  /// Lanza [InvalidRecurrenceRuleException] si alguna validacion falla.
  ///
  /// Ejemplo:
  /// ```dart
  /// final rule = RecurrenceRule(
  ///   frequency: RecurrenceFrequency.weekly,
  ///   interval: 2,
  ///   byDays: [WeekDay.monday],
  ///   startDate: DateTime.now(),
  /// );
  /// RecurrenceRuleValidator.validate(rule); // Lanza excepcion si es invalida
  /// ```
  static void validate(RecurrenceRule rule) {
    // Validar intervalo
    validateInterval(rule.interval);

    // Validar frecuencia y reglas especificas
    validateFrequency(rule);

    // Validar dias de la semana si estan definidos
    if (rule.byDays.isNotEmpty) {
      validateByDays(rule.byDays, rule.frequency);
    }

    // Validar dias del mes si estan definidos
    if (rule.byMonthDays.isNotEmpty) {
      validateByMonthDays(rule.byMonthDays);
    }

    // Validar meses si estan definidos
    if (rule.byMonths.isNotEmpty) {
      validateByMonths(rule.byMonths);
    }

    // Validar posicion de semana si esta definida
    if (rule.weekPosition != null) {
      validateWeekPosition(rule.weekPosition);
    }

    // Validar rango de fechas
    validateDateRange(rule.startDate, rule.endDate);

    // Validar conteo si esta definido
    if (rule.count != null) {
      validateCount(rule.count);
    }
  }

  /// Valida las reglas especificas segun la frecuencia.
  ///
  /// Cada frecuencia tiene requisitos particulares:
  /// - **Diaria**: byDays es opcional (filtra dias especificos)
  /// - **Semanal**: byDays es opcional (usa dia de startDate si esta vacio)
  /// - **Mensual**: Requiere byMonthDays O (weekPosition + byDays) O usa dia de startDate
  /// - **Anual**: Similar a mensual, con validacion adicional de byMonths
  ///
  /// Lanza [InvalidRecurrenceRuleException] si la configuracion no es valida
  /// para la frecuencia especificada.
  static void validateFrequency(RecurrenceRule rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        _validateDailyFrequency(rule);
        break;
      case RecurrenceFrequency.weekly:
        _validateWeeklyFrequency(rule);
        break;
      case RecurrenceFrequency.monthly:
        _validateMonthlyFrequency(rule);
        break;
      case RecurrenceFrequency.yearly:
        _validateYearlyFrequency(rule);
        break;
    }
  }

  /// Valida reglas de frecuencia diaria.
  static void _validateDailyFrequency(RecurrenceRule rule) {
    // Para frecuencia diaria, weekPosition no tiene sentido
    if (rule.weekPosition != null) {
      throw InvalidRecurrenceRuleException(
        message:
            'weekPosition no es valido para frecuencia diaria: ${rule.weekPosition}',
        userMessage:
            'La posicion de semana no aplica para tareas diarias.',
        failedComponent: 'BYSETPOS',
        operation: 'validate_daily_frequency',
        debugContext: {
          'weekPosition': rule.weekPosition,
          'frequency': rule.frequency.name,
        },
      );
    }

    // byMonthDays no tiene sentido para diario
    if (rule.byMonthDays.isNotEmpty) {
      throw InvalidRecurrenceRuleException(
        message:
            'byMonthDays no es valido para frecuencia diaria: ${rule.byMonthDays}',
        userMessage:
            'Los dias del mes no aplican para tareas diarias.',
        failedComponent: 'BYMONTHDAY',
        operation: 'validate_daily_frequency',
        debugContext: {
          'byMonthDays': rule.byMonthDays,
          'frequency': rule.frequency.name,
        },
      );
    }
  }

  /// Valida reglas de frecuencia semanal.
  static void _validateWeeklyFrequency(RecurrenceRule rule) {
    // Para frecuencia semanal, weekPosition no tiene sentido
    if (rule.weekPosition != null) {
      throw InvalidRecurrenceRuleException(
        message:
            'weekPosition no es valido para frecuencia semanal: ${rule.weekPosition}',
        userMessage:
            'La posicion de semana no aplica para tareas semanales.',
        failedComponent: 'BYSETPOS',
        operation: 'validate_weekly_frequency',
        debugContext: {
          'weekPosition': rule.weekPosition,
          'frequency': rule.frequency.name,
        },
      );
    }

    // byMonthDays no tiene sentido para semanal
    if (rule.byMonthDays.isNotEmpty) {
      throw InvalidRecurrenceRuleException(
        message:
            'byMonthDays no es valido para frecuencia semanal: ${rule.byMonthDays}',
        userMessage:
            'Los dias del mes no aplican para tareas semanales.',
        failedComponent: 'BYMONTHDAY',
        operation: 'validate_weekly_frequency',
        debugContext: {
          'byMonthDays': rule.byMonthDays,
          'frequency': rule.frequency.name,
        },
      );
    }
  }

  /// Valida reglas de frecuencia mensual.
  static void _validateMonthlyFrequency(RecurrenceRule rule) {
    // Si tiene weekPosition, debe tener byDays
    if (rule.weekPosition != null && rule.byDays.isEmpty) {
      throw InvalidRecurrenceRuleException(
        message:
            'weekPosition requiere byDays para frecuencia mensual',
        userMessage:
            'Debes seleccionar al menos un dia para usar la posicion de semana.',
        failedComponent: 'BYDAY',
        operation: 'validate_monthly_frequency',
        debugContext: {
          'weekPosition': rule.weekPosition,
          'byDays': rule.byDays,
          'frequency': rule.frequency.name,
        },
      );
    }

    // No puede tener ambos byMonthDays y weekPosition al mismo tiempo
    if (rule.byMonthDays.isNotEmpty && rule.weekPosition != null) {
      throw InvalidRecurrenceRuleException(
        message:
            'No se puede combinar byMonthDays con weekPosition',
        userMessage:
            'Usa dias del mes O posicion de semana, pero no ambos.',
        failedComponent: 'BYMONTHDAY',
        operation: 'validate_monthly_frequency',
        debugContext: {
          'byMonthDays': rule.byMonthDays,
          'weekPosition': rule.weekPosition,
          'frequency': rule.frequency.name,
        },
      );
    }
  }

  /// Valida reglas de frecuencia anual.
  static void _validateYearlyFrequency(RecurrenceRule rule) {
    // Si tiene weekPosition, debe tener byDays
    if (rule.weekPosition != null && rule.byDays.isEmpty) {
      throw InvalidRecurrenceRuleException(
        message:
            'weekPosition requiere byDays para frecuencia anual',
        userMessage:
            'Debes seleccionar al menos un dia para usar la posicion de semana.',
        failedComponent: 'BYDAY',
        operation: 'validate_yearly_frequency',
        debugContext: {
          'weekPosition': rule.weekPosition,
          'byDays': rule.byDays,
          'frequency': rule.frequency.name,
        },
      );
    }

    // No puede tener ambos byMonthDays y weekPosition al mismo tiempo
    if (rule.byMonthDays.isNotEmpty && rule.weekPosition != null) {
      throw InvalidRecurrenceRuleException(
        message:
            'No se puede combinar byMonthDays con weekPosition',
        userMessage:
            'Usa dias del mes O posicion de semana, pero no ambos.',
        failedComponent: 'BYMONTHDAY',
        operation: 'validate_yearly_frequency',
        debugContext: {
          'byMonthDays': rule.byMonthDays,
          'weekPosition': rule.weekPosition,
          'frequency': rule.frequency.name,
        },
      );
    }
  }

  /// Valida que el intervalo este dentro del rango permitido (1-365).
  ///
  /// El intervalo representa cuantas unidades de frecuencia hay entre ocurrencias.
  /// Por ejemplo, interval=2 con frecuencia semanal significa cada 2 semanas.
  ///
  /// Lanza [InvalidRecurrenceRuleException] si el intervalo es menor a 1 o mayor a 365.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateInterval(2);  // OK
  /// RecurrenceRuleValidator.validateInterval(0);  // Lanza excepcion
  /// RecurrenceRuleValidator.validateInterval(400); // Lanza excepcion
  /// ```
  static void validateInterval(int interval) {
    if (interval < _minInterval) {
      throw InvalidRecurrenceRuleException.invalidInterval(
        intervalValue: interval,
        taskId: null,
      );
    }

    if (interval > _maxInterval) {
      throw InvalidRecurrenceRuleException(
        message:
            'Intervalo fuera de rango: $interval (maximo permitido: $_maxInterval)',
        userMessage:
            'El intervalo debe ser entre $_minInterval y $_maxInterval.',
        failedComponent: 'INTERVAL',
        operation: 'validate_interval',
        debugContext: {
          'interval': interval,
          'minAllowed': _minInterval,
          'maxAllowed': _maxInterval,
        },
      );
    }
  }

  /// Valida que los dias de la semana sean apropiados para la frecuencia.
  ///
  /// La lista de dias no debe contener duplicados y debe ser apropiada
  /// para la frecuencia especificada:
  /// - **Diaria/Semanal**: Cualquier dia es valido
  /// - **Mensual/Anual**: Solo valido cuando se usa con weekPosition
  ///
  /// Lanza [InvalidRecurrenceRuleException] si hay dias duplicados o
  /// la configuracion no es apropiada para la frecuencia.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateByDays(
  ///   [WeekDay.monday, WeekDay.wednesday],
  ///   RecurrenceFrequency.weekly,
  /// ); // OK
  /// ```
  static void validateByDays(List<WeekDay> days, RecurrenceFrequency freq) {
    if (days.isEmpty) {
      return; // Lista vacia es valida (usa valores por defecto)
    }

    // Verificar duplicados
    final uniqueDays = days.toSet();
    if (uniqueDays.length != days.length) {
      final duplicates = <WeekDay>[];
      final seen = <WeekDay>{};
      for (final day in days) {
        if (seen.contains(day)) {
          duplicates.add(day);
        }
        seen.add(day);
      }

      throw InvalidRecurrenceRuleException(
        message:
            'Dias duplicados en byDays: ${duplicates.map((d) => d.name).join(", ")}',
        userMessage:
            'No puedes seleccionar el mismo dia mas de una vez.',
        failedComponent: 'BYDAY',
        operation: 'validate_bydays',
        debugContext: {
          'days': days.map((d) => d.name).toList(),
          'duplicates': duplicates.map((d) => d.name).toList(),
        },
      );
    }
  }

  /// Valida que los dias del mes esten en el rango valido (-31 a 31, excluyendo 0).
  ///
  /// Los dias positivos (1-31) representan dias desde el inicio del mes.
  /// Los dias negativos (-1 a -31) representan dias desde el final del mes.
  /// El valor 0 no es valido.
  ///
  /// Lanza [InvalidRecurrenceRuleException] si algun dia esta fuera de rango o es 0.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateByMonthDays([1, 15, -1]); // OK (1, 15, ultimo dia)
  /// RecurrenceRuleValidator.validateByMonthDays([0]);         // Lanza excepcion
  /// RecurrenceRuleValidator.validateByMonthDays([32]);        // Lanza excepcion
  /// ```
  static void validateByMonthDays(List<int> days) {
    if (days.isEmpty) {
      return; // Lista vacia es valida
    }

    for (final day in days) {
      if (day == 0) {
        throw InvalidRecurrenceRuleException.invalidMonthDay(
          dayValue: day,
          taskId: null,
        );
      }

      if (day < _minMonthDay || day > _maxMonthDay) {
        throw InvalidRecurrenceRuleException(
          message:
              'Dia del mes fuera de rango: $day (debe ser $_minMonthDay a $_maxMonthDay, excluyendo 0)',
          userMessage:
              'El dia del mes debe estar entre 1 y 31 (o -1 a -31 para contar desde el final).',
          failedComponent: 'BYMONTHDAY',
          operation: 'validate_monthdays',
          debugContext: {
            'day': day,
            'minAllowed': _minMonthDay,
            'maxAllowed': _maxMonthDay,
          },
        );
      }
    }

    // Verificar duplicados
    final uniqueDays = days.toSet();
    if (uniqueDays.length != days.length) {
      throw InvalidRecurrenceRuleException(
        message: 'Dias del mes duplicados en byMonthDays',
        userMessage:
            'No puedes seleccionar el mismo dia del mes mas de una vez.',
        failedComponent: 'BYMONTHDAY',
        operation: 'validate_monthdays',
        debugContext: {'days': days},
      );
    }
  }

  /// Valida que los meses esten en el rango valido (1-12).
  ///
  /// Los meses se representan con valores del 1 (enero) al 12 (diciembre).
  ///
  /// Lanza [InvalidRecurrenceRuleException] si algun mes esta fuera de rango.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateByMonths([1, 6, 12]); // OK (enero, junio, diciembre)
  /// RecurrenceRuleValidator.validateByMonths([0]);        // Lanza excepcion
  /// RecurrenceRuleValidator.validateByMonths([13]);       // Lanza excepcion
  /// ```
  static void validateByMonths(List<int> months) {
    if (months.isEmpty) {
      return; // Lista vacia es valida
    }

    for (final month in months) {
      if (month < _minMonth || month > _maxMonth) {
        throw InvalidRecurrenceRuleException.invalidMonth(
          monthValue: month,
          taskId: null,
        );
      }
    }

    // Verificar duplicados
    final uniqueMonths = months.toSet();
    if (uniqueMonths.length != months.length) {
      throw InvalidRecurrenceRuleException(
        message: 'Meses duplicados en byMonths',
        userMessage:
            'No puedes seleccionar el mismo mes mas de una vez.',
        failedComponent: 'BYMONTH',
        operation: 'validate_months',
        debugContext: {'months': months},
      );
    }
  }

  /// Valida que la posicion de semana este en el rango valido (-5 a 5, excluyendo 0).
  ///
  /// Valores positivos (1-5) indican posicion desde el inicio del mes:
  /// - 1 = primer
  /// - 2 = segundo
  /// - 3 = tercer
  /// - 4 = cuarto
  /// - 5 = quinto
  ///
  /// Valores negativos (-1 a -5) indican posicion desde el final del mes:
  /// - -1 = ultimo
  /// - -2 = penultimo
  /// - -3 = antepenultimo
  ///
  /// Lanza [InvalidRecurrenceRuleException] si la posicion esta fuera de rango o es 0.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateWeekPosition(1);  // OK (primer)
  /// RecurrenceRuleValidator.validateWeekPosition(-1); // OK (ultimo)
  /// RecurrenceRuleValidator.validateWeekPosition(0);  // Lanza excepcion
  /// RecurrenceRuleValidator.validateWeekPosition(6);  // Lanza excepcion
  /// ```
  static void validateWeekPosition(int? position) {
    if (position == null) {
      return; // null es valido (no se usa weekPosition)
    }

    if (position == 0) {
      throw InvalidRecurrenceRuleException.invalidWeekPosition(
        position: position,
        taskId: null,
      );
    }

    if (position < _minWeekPosition || position > _maxWeekPosition) {
      throw InvalidRecurrenceRuleException(
        message:
            'Posicion de semana fuera de rango: $position (debe ser $_minWeekPosition a $_maxWeekPosition, excluyendo 0)',
        userMessage:
            'La posicion de semana debe ser entre 1-5 o -1 a -5.',
        failedComponent: 'BYSETPOS',
        operation: 'validate_week_position',
        debugContext: {
          'position': position,
          'minAllowed': _minWeekPosition,
          'maxAllowed': _maxWeekPosition,
        },
      );
    }
  }

  /// Valida que el rango de fechas sea valido (endDate debe ser despues de startDate).
  ///
  /// Si endDate es null, la validacion pasa (recurrencia sin fecha de fin).
  /// Si endDate esta definido, debe ser posterior a startDate.
  ///
  /// Lanza [DateRangeException] si endDate es anterior o igual a startDate.
  ///
  /// Ejemplo:
  /// ```dart
  /// final start = DateTime(2024, 1, 1);
  /// final end = DateTime(2024, 12, 31);
  /// RecurrenceRuleValidator.validateDateRange(start, end); // OK
  /// RecurrenceRuleValidator.validateDateRange(end, start); // Lanza excepcion
  /// ```
  static void validateDateRange(DateTime start, DateTime? end) {
    if (end == null) {
      return; // Sin fecha de fin es valido
    }

    // Normalizar fechas (solo comparar dia, ignorar hora)
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw DateRangeException.startAfterEnd(
        startDate: start,
        endDate: end,
        taskId: null,
      );
    }

    // Permitir mismo dia (recurrencia de un solo dia)
    // No lanzar excepcion si son iguales
  }

  /// Valida que el conteo de ocurrencias sea positivo.
  ///
  /// El conteo representa el numero maximo de ocurrencias de la recurrencia.
  /// Si es null, la recurrencia continua indefinidamente (o hasta endDate).
  ///
  /// Lanza [InvalidRecurrenceRuleException] si count es menor o igual a 0.
  ///
  /// Ejemplo:
  /// ```dart
  /// RecurrenceRuleValidator.validateCount(10);   // OK
  /// RecurrenceRuleValidator.validateCount(null); // OK
  /// RecurrenceRuleValidator.validateCount(0);    // Lanza excepcion
  /// RecurrenceRuleValidator.validateCount(-1);   // Lanza excepcion
  /// ```
  static void validateCount(int? count) {
    if (count == null) {
      return; // null es valido (sin limite de ocurrencias)
    }

    if (count <= 0) {
      throw InvalidRecurrenceRuleException.invalidCount(
        countValue: count,
        taskId: null,
      );
    }
  }
}

// =============================================================================
// DATE RANGE VALIDATOR
// =============================================================================

/// Validador para rangos de fechas.
///
/// Proporciona metodos para validar que los rangos de fechas sean coherentes
/// y que las fechas cumplan con restricciones especificas (no en el pasado, etc.).
///
/// Todos los metodos que lanzan excepciones usan [DateRangeException] con
/// mensajes descriptivos en espanol.
class DateRangeValidator {
  /// Valida que un rango de fechas sea valido.
  ///
  /// Verifica que:
  /// - La fecha de inicio no sea posterior a la fecha de fin
  /// - Ambas fechas sean validas
  ///
  /// Lanza [DateRangeException] si el rango es invalido.
  ///
  /// Ejemplo:
  /// ```dart
  /// final start = DateTime(2024, 1, 1);
  /// final end = DateTime(2024, 12, 31);
  /// DateRangeValidator.validate(start, end); // OK
  /// DateRangeValidator.validate(end, start); // Lanza excepcion
  /// ```
  static void validate(DateTime start, DateTime end) {
    // Normalizar fechas (solo comparar dia, ignorar hora)
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw DateRangeException.startAfterEnd(
        startDate: start,
        endDate: end,
        taskId: null,
      );
    }
  }

  /// Valida que una fecha no este en el pasado.
  ///
  /// Por defecto, la fecha de hoy se considera valida ([allowToday] = true).
  /// Si [allowToday] es false, la fecha debe ser estrictamente futura.
  ///
  /// Lanza [DateRangeException] si la fecha esta en el pasado.
  ///
  /// Ejemplo:
  /// ```dart
  /// final tomorrow = DateTime.now().add(Duration(days: 1));
  /// DateRangeValidator.validateNotInPast(tomorrow); // OK
  ///
  /// final yesterday = DateTime.now().subtract(Duration(days: 1));
  /// DateRangeValidator.validateNotInPast(yesterday); // Lanza excepcion
  ///
  /// final today = DateTime.now();
  /// DateRangeValidator.validateNotInPast(today, allowToday: true);  // OK
  /// DateRangeValidator.validateNotInPast(today, allowToday: false); // Lanza excepcion
  /// ```
  static void validateNotInPast(DateTime date, {bool allowToday = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (allowToday) {
      // La fecha puede ser hoy o futura
      if (normalizedDate.isBefore(today)) {
        throw DateRangeException.dateInPast(
          date: date,
          fieldName: 'fecha',
          taskId: null,
        );
      }
    } else {
      // La fecha debe ser estrictamente futura
      if (normalizedDate.isBefore(today) ||
          normalizedDate.isAtSameMomentAs(today)) {
        throw DateRangeException.dateInPast(
          date: date,
          fieldName: 'fecha',
          taskId: null,
        );
      }
    }
  }

  /// Verifica si un rango de fechas es valido sin lanzar excepcion.
  ///
  /// Retorna true si el rango es valido (end >= start), false en caso contrario.
  /// Esta version es util para validaciones condicionales donde no se desea
  /// manejar excepciones.
  ///
  /// Ejemplo:
  /// ```dart
  /// final start = DateTime(2024, 1, 1);
  /// final end = DateTime(2024, 12, 31);
  ///
  /// if (DateRangeValidator.isValidRange(start, end)) {
  ///   // Procesar rango valido
  /// }
  /// ```
  static bool isValidRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    return !normalizedEnd.isBefore(normalizedStart);
  }

  /// Verifica si una fecha esta en el pasado sin lanzar excepcion.
  ///
  /// Retorna true si la fecha NO esta en el pasado, false si esta en el pasado.
  /// Por defecto, la fecha de hoy se considera valida ([allowToday] = true).
  ///
  /// Ejemplo:
  /// ```dart
  /// final tomorrow = DateTime.now().add(Duration(days: 1));
  /// DateRangeValidator.isNotInPast(tomorrow); // true
  ///
  /// final yesterday = DateTime.now().subtract(Duration(days: 1));
  /// DateRangeValidator.isNotInPast(yesterday); // false
  /// ```
  static bool isNotInPast(DateTime date, {bool allowToday = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (allowToday) {
      return !normalizedDate.isBefore(today);
    } else {
      return normalizedDate.isAfter(today);
    }
  }

  /// Valida que una fecha no exceda un limite maximo en el futuro.
  ///
  /// Util para evitar que los usuarios programen tareas demasiado lejanas.
  ///
  /// Lanza [DateRangeException] si la fecha excede el limite.
  ///
  /// Ejemplo:
  /// ```dart
  /// final oneYear = Duration(days: 365);
  /// final nextMonth = DateTime.now().add(Duration(days: 30));
  /// DateRangeValidator.validateNotTooFar(nextMonth, maxFuture: oneYear); // OK
  ///
  /// final twoYears = DateTime.now().add(Duration(days: 730));
  /// DateRangeValidator.validateNotTooFar(twoYears, maxFuture: oneYear); // Lanza excepcion
  /// ```
  static void validateNotTooFar(DateTime date, {required Duration maxFuture}) {
    final now = DateTime.now();
    final maxDate = now.add(maxFuture);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedMax = DateTime(maxDate.year, maxDate.month, maxDate.day);

    if (normalizedDate.isAfter(normalizedMax)) {
      throw DateRangeException.dateTooFar(
        date: date,
        maxFuture: maxFuture,
        taskId: null,
      );
    }
  }

  /// Valida que la duracion del rango no exceda un limite maximo.
  ///
  /// Util para limitar la duracion de recurrencias o eventos.
  ///
  /// Lanza [DateRangeException] si la duracion excede el limite.
  ///
  /// Ejemplo:
  /// ```dart
  /// final start = DateTime(2024, 1, 1);
  /// final end = DateTime(2024, 6, 30);
  /// final maxDuration = Duration(days: 365);
  /// DateRangeValidator.validateMaxDuration(start, end, maxDuration: maxDuration); // OK
  /// ```
  static void validateMaxDuration(
    DateTime start,
    DateTime end, {
    required Duration maxDuration,
  }) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final duration = normalizedEnd.difference(normalizedStart);

    if (duration > maxDuration) {
      throw DateRangeException(
        message:
            'Duracion del rango (${duration.inDays} dias) excede el maximo permitido (${maxDuration.inDays} dias)',
        userMessage:
            'El rango de fechas no puede ser mayor a ${maxDuration.inDays} dias.',
        startDate: start,
        endDate: end,
        constraintViolated: 'duration <= ${maxDuration.inDays} days',
        operation: 'validate_max_duration',
        debugContext: {
          'durationDays': duration.inDays,
          'maxDurationDays': maxDuration.inDays,
        },
      );
    }
  }
}
