import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'recurrence_rule.g.dart';

/// Frecuencia de recurrencia de una tarea.
@HiveType(typeId: 10)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  yearly,
}

/// Extension para RecurrenceFrequency.
extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  /// Nombre en espanol.
  String get spanishName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diario';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  /// Codigo RFC 5545.
  String get rfc5545Code {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }

  /// Crear desde codigo RFC 5545.
  static RecurrenceFrequency fromRfc5545Code(String code) {
    switch (code.toUpperCase()) {
      case 'DAILY':
        return RecurrenceFrequency.daily;
      case 'WEEKLY':
        return RecurrenceFrequency.weekly;
      case 'MONTHLY':
        return RecurrenceFrequency.monthly;
      case 'YEARLY':
        return RecurrenceFrequency.yearly;
      default:
        throw ArgumentError('Codigo RFC 5545 invalido: $code');
    }
  }
}

/// Dias de la semana (ISO 8601: Lunes=1, Domingo=7).
@HiveType(typeId: 11)
enum WeekDay {
  @HiveField(0)
  monday,

  @HiveField(1)
  tuesday,

  @HiveField(2)
  wednesday,

  @HiveField(3)
  thursday,

  @HiveField(4)
  friday,

  @HiveField(5)
  saturday,

  @HiveField(6)
  sunday,
}

/// Extension para WeekDay con propiedades utiles.
extension WeekDayExtension on WeekDay {
  /// Valor numerico ISO 8601 (Lunes=1, Domingo=7).
  int get isoValue {
    switch (this) {
      case WeekDay.monday:
        return 1;
      case WeekDay.tuesday:
        return 2;
      case WeekDay.wednesday:
        return 3;
      case WeekDay.thursday:
        return 4;
      case WeekDay.friday:
        return 5;
      case WeekDay.saturday:
        return 6;
      case WeekDay.sunday:
        return 7;
    }
  }

  /// Valor para DateTime.weekday de Dart (Lunes=1, Domingo=7).
  int get dartWeekday => isoValue;

  /// Codigo RFC 5545 (MO, TU, WE, TH, FR, SA, SU).
  String get rfc5545Code {
    switch (this) {
      case WeekDay.monday:
        return 'MO';
      case WeekDay.tuesday:
        return 'TU';
      case WeekDay.wednesday:
        return 'WE';
      case WeekDay.thursday:
        return 'TH';
      case WeekDay.friday:
        return 'FR';
      case WeekDay.saturday:
        return 'SA';
      case WeekDay.sunday:
        return 'SU';
    }
  }

  /// Nombre en espanol.
  String get spanishName {
    switch (this) {
      case WeekDay.monday:
        return 'Lunes';
      case WeekDay.tuesday:
        return 'Martes';
      case WeekDay.wednesday:
        return 'Miercoles';
      case WeekDay.thursday:
        return 'Jueves';
      case WeekDay.friday:
        return 'Viernes';
      case WeekDay.saturday:
        return 'Sabado';
      case WeekDay.sunday:
        return 'Domingo';
    }
  }

  /// Nombre corto en espanol (3 letras).
  String get spanishShortName {
    switch (this) {
      case WeekDay.monday:
        return 'Lun';
      case WeekDay.tuesday:
        return 'Mar';
      case WeekDay.wednesday:
        return 'Mie';
      case WeekDay.thursday:
        return 'Jue';
      case WeekDay.friday:
        return 'Vie';
      case WeekDay.saturday:
        return 'Sab';
      case WeekDay.sunday:
        return 'Dom';
    }
  }

  /// Crear desde valor ISO 8601 (1-7).
  static WeekDay fromIsoValue(int value) {
    switch (value) {
      case 1:
        return WeekDay.monday;
      case 2:
        return WeekDay.tuesday;
      case 3:
        return WeekDay.wednesday;
      case 4:
        return WeekDay.thursday;
      case 5:
        return WeekDay.friday;
      case 6:
        return WeekDay.saturday;
      case 7:
        return WeekDay.sunday;
      default:
        throw ArgumentError('Valor ISO invalido: $value. Debe ser 1-7.');
    }
  }

  /// Crear desde codigo RFC 5545.
  static WeekDay fromRfc5545Code(String code) {
    switch (code.toUpperCase()) {
      case 'MO':
        return WeekDay.monday;
      case 'TU':
        return WeekDay.tuesday;
      case 'WE':
        return WeekDay.wednesday;
      case 'TH':
        return WeekDay.thursday;
      case 'FR':
        return WeekDay.friday;
      case 'SA':
        return WeekDay.saturday;
      case 'SU':
        return WeekDay.sunday;
      default:
        throw ArgumentError('Codigo RFC 5545 invalido: $code');
    }
  }

  /// Crear desde DateTime.weekday de Dart.
  static WeekDay fromDartWeekday(int weekday) => fromIsoValue(weekday);
}

/// Paridad de semana para patrones alternados (Semana A / Semana B).
@HiveType(typeId: 12)
enum WeekParity {
  @HiveField(0)
  a,

  @HiveField(1)
  b,
}

/// Extension para WeekParity.
extension WeekParityExtension on WeekParity {
  /// Nombre en espanol.
  String get spanishName {
    switch (this) {
      case WeekParity.a:
        return 'Semana A';
      case WeekParity.b:
        return 'Semana B';
    }
  }

  /// Nombre corto.
  String get shortName {
    switch (this) {
      case WeekParity.a:
        return 'A';
      case WeekParity.b:
        return 'B';
    }
  }
}

/// Regla de recurrencia para tareas.
/// Sigue el estandar RFC 5545 (iCalendar) para compatibilidad.
@HiveType(typeId: 9)
class RecurrenceRule extends HiveObject {
  /// Frecuencia de la recurrencia.
  @HiveField(0)
  late RecurrenceFrequency frequency;

  /// Intervalo entre ocurrencias (por defecto 1).
  /// Ej: interval=2 con frequency=weekly significa cada 2 semanas.
  @HiveField(1)
  late int interval;

  /// Dias de la semana para patrones semanales.
  /// Ej: [WeekDay.tuesday, WeekDay.thursday] para "Mar y Jue".
  @HiveField(2)
  late List<WeekDay> byDays;

  /// Dias del mes (1-31, o negativos desde el final: -1 = ultimo dia).
  @HiveField(3)
  late List<int> byMonthDays;

  /// Meses del ano (1-12).
  @HiveField(4)
  late List<int> byMonths;

  /// Posicion de la semana dentro del mes.
  /// 1-5 para "primer", "segundo", etc.
  /// -1 a -5 para "ultimo", "penultimo", etc.
  /// Ej: weekPosition=1 con byDays=[monday] = "primer lunes del mes".
  @HiveField(5)
  int? weekPosition;

  /// Paridad de semana para patrones alternados.
  @HiveField(6)
  WeekParity? weekParity;

  /// Fecha de inicio de la recurrencia.
  @HiveField(7)
  late DateTime startDate;

  /// Fecha de fin de la recurrencia (opcional).
  @HiveField(8)
  DateTime? endDate;

  /// Numero maximo de ocurrencias (opcional).
  @HiveField(9)
  int? count;

  /// Fechas de excepcion donde no aplica la recurrencia.
  @HiveField(10)
  late List<DateTime> exceptionDates;

  /// Zona horaria (formato IANA, ej: "America/Mexico_City").
  @HiveField(11)
  String? timezone;

  /// Preset para patrones rapidos.
  /// Valores: "workdays", "weekends", "mwf", "tth", "biweekly", "quarterly".
  @HiveField(12)
  String? preset;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    List<WeekDay>? byDays,
    List<int>? byMonthDays,
    List<int>? byMonths,
    this.weekPosition,
    this.weekParity,
    required this.startDate,
    this.endDate,
    this.count,
    List<DateTime>? exceptionDates,
    this.timezone,
    this.preset,
  })  : byDays = byDays ?? [],
        byMonthDays = byMonthDays ?? [],
        byMonths = byMonths ?? [],
        exceptionDates = exceptionDates ?? [];

  // ============================================================
  // METODOS DE CALCULO DE OCURRENCIAS
  // ============================================================

  /// Calcula la proxima ocurrencia despues de [from].
  /// Retorna null si no hay mas ocurrencias.
  DateTime? nextOccurrence(DateTime from) {
    final occurrences = nextOccurrences(from, 1);
    return occurrences.isNotEmpty ? occurrences.first : null;
  }

  /// Genera una lista de las proximas [count] ocurrencias despues de [from].
  List<DateTime> nextOccurrences(DateTime from, int count) {
    if (count <= 0) return [];

    final List<DateTime> results = [];
    DateTime current = _normalizeDate(from);
    int occurrenceCount = 0;
    int maxIterations = 10000; // Seguridad para evitar loops infinitos
    int iterations = 0;

    while (results.length < count && iterations < maxIterations) {
      iterations++;

      // Avanzar al siguiente candidato
      current = _nextCandidate(current, results.isEmpty);

      // Verificar limites
      if (endDate != null && current.isAfter(endDate!)) break;
      if (this.count != null && occurrenceCount >= this.count!) break;

      // Verificar si coincide con el patron
      if (_matchesPattern(current)) {
        // Verificar que no sea una fecha de excepcion
        if (!_isException(current)) {
          // Verificar paridad de semana si aplica
          if (weekParity == null || _matchesWeekParity(current)) {
            results.add(current);
            occurrenceCount++;
          }
        }
      }

      // Avanzar un dia para la siguiente iteracion (DST-safe)
      current = DateTime(current.year, current.month, current.day + 1);
    }

    return results;
  }

  /// Normaliza una fecha removiendo la hora.
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Obtiene el siguiente candidato a evaluar.
  DateTime _nextCandidate(DateTime from, bool isFirst) {
    DateTime candidate = from;

    // Si es la primera iteracion, empezar desde startDate si from es anterior
    if (isFirst && candidate.isBefore(startDate)) {
      candidate = _normalizeDate(startDate);
    }

    return candidate;
  }

  /// Verifica si una fecha coincide con el patron de recurrencia.
  bool _matchesPattern(DateTime date) {
    // Verificar que la fecha no sea anterior a startDate
    if (date.isBefore(_normalizeDate(startDate))) return false;

    // Verificar intervalo
    if (!_matchesInterval(date)) return false;

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _matchesDailyPattern(date);
      case RecurrenceFrequency.weekly:
        return _matchesWeeklyPattern(date);
      case RecurrenceFrequency.monthly:
        return _matchesMonthlyPattern(date);
      case RecurrenceFrequency.yearly:
        return _matchesYearlyPattern(date);
    }
  }

  /// Verifica si la fecha cumple con el intervalo.
  bool _matchesInterval(DateTime date) {
    if (interval <= 1) return true;

    final start = _normalizeDate(startDate);
    final daysDiff = date.difference(start).inDays;

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return daysDiff % interval == 0;
      case RecurrenceFrequency.weekly:
        final weeksDiff = daysDiff ~/ 7;
        return weeksDiff % interval == 0;
      case RecurrenceFrequency.monthly:
        final monthsDiff = _monthsDifference(start, date);
        return monthsDiff % interval == 0;
      case RecurrenceFrequency.yearly:
        final yearsDiff = date.year - start.year;
        return yearsDiff % interval == 0;
    }
  }

  /// Calcula la diferencia en meses entre dos fechas.
  int _monthsDifference(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Patron diario.
  bool _matchesDailyPattern(DateTime date) {
    // Para diario, verificar byDays si esta definido
    if (byDays.isNotEmpty) {
      final weekDay = WeekDayExtension.fromDartWeekday(date.weekday);
      return byDays.contains(weekDay);
    }
    return true;
  }

  /// Patron semanal.
  bool _matchesWeeklyPattern(DateTime date) {
    if (byDays.isEmpty) {
      // Si no hay dias especificos, usar el dia de la semana de startDate
      return date.weekday == startDate.weekday;
    }

    final weekDay = WeekDayExtension.fromDartWeekday(date.weekday);
    return byDays.contains(weekDay);
  }

  /// Patron mensual.
  bool _matchesMonthlyPattern(DateTime date) {
    // Verificar meses si esta definido
    if (byMonths.isNotEmpty && !byMonths.contains(date.month)) {
      return false;
    }

    // Patron por posicion de semana (ej: "primer lunes")
    if (weekPosition != null && byDays.isNotEmpty) {
      return _matchesWeekPositionPattern(date);
    }

    // Patron por dias del mes
    if (byMonthDays.isNotEmpty) {
      return _matchesMonthDayPattern(date);
    }

    // Por defecto, usar el dia del mes de startDate
    return _matchesDayOfMonth(date, startDate.day);
  }

  /// Verifica patron de posicion de semana (ej: "segundo martes").
  bool _matchesWeekPositionPattern(DateTime date) {
    final weekDay = WeekDayExtension.fromDartWeekday(date.weekday);
    if (!byDays.contains(weekDay)) return false;

    final position = weekPosition!;

    if (position > 0) {
      // Posicion desde el inicio del mes
      int count = 0;
      for (int d = 1; d <= date.day; d++) {
        final checkDate = DateTime(date.year, date.month, d);
        if (checkDate.weekday == date.weekday) {
          count++;
        }
      }
      return count == position;
    } else {
      // Posicion desde el final del mes
      final lastDay = _lastDayOfMonth(date.year, date.month);
      int count = 0;
      for (int d = lastDay; d >= date.day; d--) {
        final checkDate = DateTime(date.year, date.month, d);
        if (checkDate.weekday == date.weekday) {
          count++;
        }
      }
      return count == -position;
    }
  }

  /// Verifica patron de dias del mes.
  bool _matchesMonthDayPattern(DateTime date) {
    for (final day in byMonthDays) {
      if (_matchesDayOfMonth(date, day)) {
        return true;
      }
    }
    return false;
  }

  /// Verifica si una fecha coincide con un dia del mes especifico.
  /// Soporta dias negativos (-1 = ultimo dia, -2 = penultimo, etc).
  bool _matchesDayOfMonth(DateTime date, int targetDay) {
    final lastDay = _lastDayOfMonth(date.year, date.month);

    if (targetDay > 0) {
      // Dia positivo: ajustar si el mes no tiene suficientes dias
      final adjustedDay = targetDay > lastDay ? lastDay : targetDay;
      return date.day == adjustedDay;
    } else {
      // Dia negativo: contar desde el final
      final actualDay = lastDay + targetDay + 1;
      return date.day == actualDay;
    }
  }

  /// Patron anual.
  bool _matchesYearlyPattern(DateTime date) {
    // Verificar mes
    if (byMonths.isNotEmpty) {
      if (!byMonths.contains(date.month)) return false;
    } else {
      if (date.month != startDate.month) return false;
    }

    // Patron por posicion de semana
    if (weekPosition != null && byDays.isNotEmpty) {
      return _matchesWeekPositionPattern(date);
    }

    // Patron por dias del mes
    if (byMonthDays.isNotEmpty) {
      return _matchesMonthDayPattern(date);
    }

    // Por defecto, usar el dia del mes de startDate
    return _matchesDayOfMonth(date, startDate.day);
  }

  /// Obtiene el ultimo dia del mes.
  int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Verifica si una fecha es una excepcion.
  bool _isException(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return exceptionDates.any((ex) => _normalizeDate(ex) == normalizedDate);
  }

  /// Verifica si una fecha coincide con la paridad de semana.
  bool _matchesWeekParity(DateTime date) {
    if (weekParity == null) return true;

    final weekNumber = getIsoWeekNumber(date);
    final isEvenWeek = weekNumber % 2 == 0;

    // Semana A = impar, Semana B = par
    return (weekParity == WeekParity.a) ? !isEvenWeek : isEvenWeek;
  }

  /// Verifica si una fecha especifica coincide con esta regla.
  bool matchesDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);

    // Verificar limites
    if (normalizedDate.isBefore(_normalizeDate(startDate))) return false;
    if (endDate != null && normalizedDate.isAfter(_normalizeDate(endDate!))) {
      return false;
    }

    // Verificar excepciones
    if (_isException(normalizedDate)) return false;

    // Verificar patron
    if (!_matchesPattern(normalizedDate)) return false;

    // Verificar paridad
    if (!_matchesWeekParity(normalizedDate)) return false;

    return true;
  }

  // ============================================================
  // METODOS DE VISUALIZACION
  // ============================================================

  /// Genera una cadena legible en espanol describiendo la recurrencia.
  String toDisplayString([TimeOfDay? taskTime]) {
    final StringBuffer buffer = StringBuffer();

    // Preset rapidos
    if (preset != null) {
      final presetString = _presetToSpanish(preset!);
      if (presetString != null) {
        buffer.write(presetString);
        if (taskTime != null) {
          buffer.write(' a las ${_formatTime(taskTime)}');
        }
        return buffer.toString();
      }
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        buffer.write(_dailyToDisplayString());
        break;
      case RecurrenceFrequency.weekly:
        buffer.write(_weeklyToDisplayString());
        break;
      case RecurrenceFrequency.monthly:
        buffer.write(_monthlyToDisplayString());
        break;
      case RecurrenceFrequency.yearly:
        buffer.write(_yearlyToDisplayString());
        break;
    }

    // Agregar paridad de semana
    if (weekParity != null) {
      buffer.write(' (${weekParity!.spanishName})');
    }

    // Agregar hora si se proporciona
    if (taskTime != null) {
      buffer.write(' a las ${_formatTime(taskTime)}');
    }

    // Agregar fecha de fin
    if (endDate != null) {
      buffer.write(' hasta el ${_formatDate(endDate!)}');
    } else if (count != null) {
      buffer.write(' ($count veces)');
    }

    return buffer.toString();
  }

  String _dailyToDisplayString() {
    if (byDays.isNotEmpty) {
      return 'Cada ${_formatDaysList(byDays)}';
    }

    if (interval == 1) {
      return 'Todos los dias';
    } else {
      return 'Cada $interval dias';
    }
  }

  String _weeklyToDisplayString() {
    final daysString =
        byDays.isEmpty ? _getWeekDayFromDate(startDate).spanishName : _formatDaysList(byDays);

    if (interval == 1) {
      return 'Cada semana el $daysString';
    } else {
      return 'Cada $interval semanas el $daysString';
    }
  }

  String _monthlyToDisplayString() {
    String dayPart;

    if (weekPosition != null && byDays.isNotEmpty) {
      final positionString = _ordinalPosition(weekPosition!);
      final dayString = byDays.length == 1 ? byDays.first.spanishName : _formatDaysList(byDays);
      dayPart = 'el $positionString $dayString';
    } else if (byMonthDays.isNotEmpty) {
      dayPart = 'el dia ${_formatMonthDays(byMonthDays)}';
    } else {
      dayPart = 'el dia ${startDate.day}';
    }

    if (interval == 1) {
      return 'Cada mes $dayPart';
    } else {
      return 'Cada $interval meses $dayPart';
    }
  }

  String _yearlyToDisplayString() {
    String datePart;

    if (weekPosition != null && byDays.isNotEmpty && byMonths.isNotEmpty) {
      final positionString = _ordinalPosition(weekPosition!);
      final dayString = byDays.first.spanishName;
      final monthString = _monthName(byMonths.first);
      datePart = 'el $positionString $dayString de $monthString';
    } else if (byMonths.isNotEmpty && byMonthDays.isNotEmpty) {
      final monthString =
          byMonths.length == 1 ? _monthName(byMonths.first) : byMonths.map(_monthName).join(', ');
      datePart = 'el ${_formatMonthDays(byMonthDays)} de $monthString';
    } else {
      datePart = 'el ${startDate.day} de ${_monthName(startDate.month)}';
    }

    if (interval == 1) {
      return 'Cada ano $datePart';
    } else {
      return 'Cada $interval anos $datePart';
    }
  }

  String _formatDaysList(List<WeekDay> days) {
    if (days.isEmpty) return '';
    if (days.length == 1) return days.first.spanishName;

    // Ordenar por valor ISO
    final sorted = List<WeekDay>.from(days)..sort((a, b) => a.isoValue.compareTo(b.isoValue));

    if (days.length == 2) {
      return '${sorted[0].spanishName} y ${sorted[1].spanishName}';
    }

    final allButLast = sorted.sublist(0, sorted.length - 1).map((d) => d.spanishName).join(', ');
    return '$allButLast y ${sorted.last.spanishName}';
  }

  String _formatMonthDays(List<int> days) {
    if (days.isEmpty) return '';

    final formatted = days.map((d) {
      if (d == -1) return 'ultimo dia';
      if (d < 0) return '${-d} dias antes del fin';
      return d.toString();
    }).toList();

    if (formatted.length == 1) return formatted.first;
    if (formatted.length == 2) return '${formatted[0]} y ${formatted[1]}';

    final allButLast = formatted.sublist(0, formatted.length - 1).join(', ');
    return '$allButLast y ${formatted.last}';
  }

  String _ordinalPosition(int position) {
    if (position > 0) {
      switch (position) {
        case 1:
          return 'primer';
        case 2:
          return 'segundo';
        case 3:
          return 'tercer';
        case 4:
          return 'cuarto';
        case 5:
          return 'quinto';
        default:
          return '${position}o';
      }
    } else {
      switch (position) {
        case -1:
          return 'ultimo';
        case -2:
          return 'penultimo';
        case -3:
          return 'antepenultimo';
        default:
          return '${-position}o desde el final';
      }
    }
  }

  String _monthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String? _presetToSpanish(String preset) {
    switch (preset) {
      case 'workdays':
        return 'Dias laborales (Lun-Vie)';
      case 'weekends':
        return 'Fines de semana (Sab-Dom)';
      case 'mwf':
        return 'Lunes, Miercoles y Viernes';
      case 'tth':
        return 'Martes y Jueves';
      case 'biweekly':
        return 'Cada dos semanas';
      case 'quarterly':
        return 'Trimestralmente';
      default:
        return null;
    }
  }

  WeekDay _getWeekDayFromDate(DateTime date) {
    return WeekDayExtension.fromDartWeekday(date.weekday);
  }

  // ============================================================
  // RFC 5545 (iCalendar) SERIALIZATION
  // ============================================================

  /// Genera una cadena en formato RFC 5545 RRULE.
  String toRfc5545String() {
    final List<String> parts = [];

    // FREQ
    parts.add('FREQ=${frequency.rfc5545Code}');

    // INTERVAL
    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }

    // BYDAY
    if (byDays.isNotEmpty) {
      final daysStr = byDays.map((d) {
        if (weekPosition != null) {
          return '$weekPosition${d.rfc5545Code}';
        }
        return d.rfc5545Code;
      }).join(',');
      parts.add('BYDAY=$daysStr');
    }

    // BYMONTHDAY
    if (byMonthDays.isNotEmpty) {
      parts.add('BYMONTHDAY=${byMonthDays.join(',')}');
    }

    // BYMONTH
    if (byMonths.isNotEmpty) {
      parts.add('BYMONTH=${byMonths.join(',')}');
    }

    // UNTIL
    if (endDate != null) {
      parts.add('UNTIL=${_dateToRfc5545(endDate!)}');
    }

    // COUNT
    if (count != null) {
      parts.add('COUNT=$count');
    }

    // WKST (week start, default Monday)
    parts.add('WKST=MO');

    return 'RRULE:${parts.join(';')}';
  }

  String _dateToRfc5545(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Parsea una cadena RFC 5545 RRULE.
  factory RecurrenceRule.fromRfc5545(String rrule, DateTime startDate) {
    // Remover prefijo RRULE: si existe
    String content = rrule;
    if (content.startsWith('RRULE:')) {
      content = content.substring(6);
    }

    final parts = content.split(';');
    final Map<String, String> params = {};

    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        final key = part.substring(0, idx);
        final value = part.substring(idx + 1);
        params[key] = value;
      }
    }

    // Parse FREQ (required)
    final freqStr = params['FREQ'] ?? 'DAILY';
    final frequency = RecurrenceFrequencyExtension.fromRfc5545Code(freqStr);

    // Parse INTERVAL
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

    // Parse BYDAY
    List<WeekDay> byDays = [];
    int? weekPosition;
    if (params.containsKey('BYDAY')) {
      final daysStr = params['BYDAY']!;
      final dayParts = daysStr.split(',');
      for (final dayPart in dayParts) {
        // Check for position prefix (e.g., "1MO", "-1FR")
        final match = RegExp(r'^(-?\d+)?([A-Z]{2})$').firstMatch(dayPart);
        if (match != null) {
          if (match.group(1) != null) {
            weekPosition = int.parse(match.group(1)!);
          }
          byDays.add(WeekDayExtension.fromRfc5545Code(match.group(2)!));
        }
      }
    }

    // Parse BYMONTHDAY
    List<int> byMonthDays = [];
    if (params.containsKey('BYMONTHDAY')) {
      byMonthDays = params['BYMONTHDAY']!.split(',').map((s) => int.parse(s)).toList();
    }

    // Parse BYMONTH
    List<int> byMonths = [];
    if (params.containsKey('BYMONTH')) {
      byMonths = params['BYMONTH']!.split(',').map((s) => int.parse(s)).toList();
    }

    // Parse UNTIL
    DateTime? endDate;
    if (params.containsKey('UNTIL')) {
      endDate = _parseRfc5545Date(params['UNTIL']!);
    }

    // Parse COUNT
    int? count;
    if (params.containsKey('COUNT')) {
      count = int.tryParse(params['COUNT']!);
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byDays: byDays,
      byMonthDays: byMonthDays,
      byMonths: byMonths,
      weekPosition: weekPosition,
      startDate: startDate,
      endDate: endDate,
      count: count,
    );
  }

  static DateTime? _parseRfc5545Date(String dateStr) {
    try {
      // Format: YYYYMMDD or YYYYMMDDTHHMMSS or YYYYMMDDTHHMMSSZ
      if (dateStr.length >= 8) {
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(4, 6));
        final day = int.parse(dateStr.substring(6, 8));

        if (dateStr.length >= 15) {
          final hour = int.parse(dateStr.substring(9, 11));
          final minute = int.parse(dateStr.substring(11, 13));
          final second = int.parse(dateStr.substring(13, 15));
          return DateTime(year, month, day, hour, minute, second);
        }

        return DateTime(year, month, day);
      }
    } catch (e) {
      // Return null on parse error
    }
    return null;
  }

  // ============================================================
  // JSON SERIALIZATION
  // ============================================================

  /// Convierte a Map para JSON/Firestore.
  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.index,
      'interval': interval,
      'byDays': byDays.map((d) => d.index).toList(),
      'byMonthDays': byMonthDays,
      'byMonths': byMonths,
      'weekPosition': weekPosition,
      'weekParity': weekParity?.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'count': count,
      'exceptionDates': exceptionDates.map((d) => d.toIso8601String()).toList(),
      'timezone': timezone,
      'preset': preset,
    };
  }

  /// Crea desde Map de JSON/Firestore.
  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.values[json['frequency'] as int? ?? 0],
      interval: json['interval'] as int? ?? 1,
      byDays: (json['byDays'] as List<dynamic>?)?.map((i) => WeekDay.values[i as int]).toList() ??
          [],
      byMonthDays: (json['byMonthDays'] as List<dynamic>?)?.map((i) => i as int).toList() ?? [],
      byMonths: (json['byMonths'] as List<dynamic>?)?.map((i) => i as int).toList() ?? [],
      weekPosition: json['weekPosition'] as int?,
      weekParity:
          json['weekParity'] != null ? WeekParity.values[json['weekParity'] as int] : null,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      count: json['count'] as int?,
      exceptionDates: (json['exceptionDates'] as List<dynamic>?)
              ?.map((s) => DateTime.parse(s as String))
              .toList() ??
          [],
      timezone: json['timezone'] as String?,
      preset: json['preset'] as String?,
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  /// Crea una copia con campos modificados (inmutable).
  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<WeekDay>? byDays,
    List<int>? byMonthDays,
    List<int>? byMonths,
    int? weekPosition,
    bool clearWeekPosition = false,
    WeekParity? weekParity,
    bool clearWeekParity = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    int? count,
    bool clearCount = false,
    List<DateTime>? exceptionDates,
    String? timezone,
    bool clearTimezone = false,
    String? preset,
    bool clearPreset = false,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byDays: byDays ?? List.from(this.byDays),
      byMonthDays: byMonthDays ?? List.from(this.byMonthDays),
      byMonths: byMonths ?? List.from(this.byMonths),
      weekPosition: clearWeekPosition ? null : (weekPosition ?? this.weekPosition),
      weekParity: clearWeekParity ? null : (weekParity ?? this.weekParity),
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      count: clearCount ? null : (count ?? this.count),
      exceptionDates: exceptionDates ?? List.from(this.exceptionDates),
      timezone: clearTimezone ? null : (timezone ?? this.timezone),
      preset: clearPreset ? null : (preset ?? this.preset),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Calcula el numero de semana ISO 8601.
  /// La semana 1 es la primera semana con al menos 4 dias en el ano.
  static int getIsoWeekNumber(DateTime date) {
    // Algoritmo ISO 8601 week number
    final weekday = date.weekday; // 1=Lunes, 7=Domingo

    // Calcular el jueves de la semana actual
    final thursdayOffset = DateTime.thursday - weekday;
    final thursday = date.add(Duration(days: thursdayOffset));

    // El ano del numero de semana es el ano del jueves
    final yearOfWeek = thursday.year;

    // Primer jueves del ano
    final jan4 = DateTime(yearOfWeek, 1, 4);
    final firstThursday = jan4.subtract(Duration(days: jan4.weekday - DateTime.thursday));

    // Calcular numero de semana
    final weekNumber = ((thursday.difference(firstThursday).inDays) / 7).floor() + 1;

    return weekNumber;
  }

  /// Calcula la paridad de semana (A/B) para una fecha.
  /// Semana A = impar, Semana B = par.
  static WeekParity getWeekParity(DateTime date) {
    final weekNumber = getIsoWeekNumber(date);
    return weekNumber % 2 == 1 ? WeekParity.a : WeekParity.b;
  }

  /// Obtiene el primer dia del mes.
  static DateTime getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// Obtiene el ultimo dia del mes.
  static DateTime getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  /// Obtiene el N-esimo dia de la semana en un mes.
  /// position: 1-5 o -1 a -5 (desde el final).
  /// weekday: 1=Lunes, 7=Domingo.
  static DateTime? getNthWeekdayOfMonth(int year, int month, int weekday, int position) {
    if (position == 0) return null;

    final firstDay = getFirstDayOfMonth(year, month);
    final lastDay = getLastDayOfMonth(year, month);

    if (position > 0) {
      // Desde el inicio
      DateTime current = firstDay;
      // Ir al primer dia de la semana deseado
      while (current.weekday != weekday) {
        current = current.add(const Duration(days: 1));
      }
      // Avanzar position-1 semanas
      current = current.add(Duration(days: (position - 1) * 7));
      // Verificar que sigue en el mismo mes
      if (current.month == month) {
        return current;
      }
    } else {
      // Desde el final
      DateTime current = lastDay;
      // Ir al ultimo dia de la semana deseado
      while (current.weekday != weekday) {
        current = current.subtract(const Duration(days: 1));
      }
      // Retroceder |position|-1 semanas
      current = current.subtract(Duration(days: ((-position) - 1) * 7));
      // Verificar que sigue en el mismo mes
      if (current.month == month) {
        return current;
      }
    }

    return null;
  }

  /// Ajusta un dia del mes para meses cortos.
  /// Ej: dia 31 en febrero -> dia 28 (o 29 en bisiesto).
  static int adjustDayForMonth(int day, int year, int month) {
    final lastDay = getLastDayOfMonth(year, month).day;
    if (day > lastDay) return lastDay;
    if (day < 1) return 1;
    return day;
  }

  // ============================================================
  // FACTORY CONSTRUCTORS FOR COMMON PATTERNS
  // ============================================================

  /// Crea una regla para dias laborales (Lunes a Viernes).
  factory RecurrenceRule.workdays({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      byDays: [
        WeekDay.monday,
        WeekDay.tuesday,
        WeekDay.wednesday,
        WeekDay.thursday,
        WeekDay.friday,
      ],
      startDate: startDate,
      endDate: endDate,
      preset: 'workdays',
    );
  }

  /// Crea una regla para fines de semana (Sabado y Domingo).
  factory RecurrenceRule.weekends({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      byDays: [WeekDay.saturday, WeekDay.sunday],
      startDate: startDate,
      endDate: endDate,
      preset: 'weekends',
    );
  }

  /// Crea una regla para Lunes, Miercoles y Viernes.
  factory RecurrenceRule.mwf({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      byDays: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday],
      startDate: startDate,
      endDate: endDate,
      preset: 'mwf',
    );
  }

  /// Crea una regla para Martes y Jueves.
  factory RecurrenceRule.tth({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      byDays: [WeekDay.tuesday, WeekDay.thursday],
      startDate: startDate,
      endDate: endDate,
      preset: 'tth',
    );
  }

  /// Crea una regla para cada dos semanas.
  factory RecurrenceRule.biweekly({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: 2,
      startDate: startDate,
      endDate: endDate,
      preset: 'biweekly',
    );
  }

  /// Crea una regla trimestral (cada 3 meses).
  factory RecurrenceRule.quarterly({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 3,
      startDate: startDate,
      endDate: endDate,
      preset: 'quarterly',
    );
  }

  /// Crea una regla para el primer dia de cada mes.
  factory RecurrenceRule.firstOfMonth({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      byMonthDays: [1],
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Crea una regla para el ultimo dia de cada mes.
  factory RecurrenceRule.lastOfMonth({required DateTime startDate, DateTime? endDate}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      byMonthDays: [-1],
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Crea una regla para el N-esimo dia de la semana del mes.
  /// Ej: primer lunes, ultimo viernes.
  factory RecurrenceRule.nthWeekdayOfMonth({
    required DateTime startDate,
    required WeekDay weekday,
    required int position,
    DateTime? endDate,
  }) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      byDays: [weekday],
      weekPosition: position,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecurrenceRule) return false;

    return frequency == other.frequency &&
        interval == other.interval &&
        _listEquals(byDays, other.byDays) &&
        _listEquals(byMonthDays, other.byMonthDays) &&
        _listEquals(byMonths, other.byMonths) &&
        weekPosition == other.weekPosition &&
        weekParity == other.weekParity &&
        _dateEquals(startDate, other.startDate) &&
        _dateEquals(endDate, other.endDate) &&
        count == other.count &&
        timezone == other.timezone &&
        preset == other.preset;
  }

  @override
  int get hashCode {
    return Object.hash(
      frequency,
      interval,
      Object.hashAll(byDays),
      Object.hashAll(byMonthDays),
      Object.hashAll(byMonths),
      weekPosition,
      weekParity,
      startDate,
      endDate,
      count,
      timezone,
      preset,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _dateEquals(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  String toString() {
    return 'RecurrenceRule(frequency: $frequency, interval: $interval, '
        'byDays: $byDays, byMonthDays: $byMonthDays, byMonths: $byMonths, '
        'weekPosition: $weekPosition, weekParity: $weekParity, '
        'startDate: $startDate, endDate: $endDate, count: $count, '
        'preset: $preset)';
  }
}
