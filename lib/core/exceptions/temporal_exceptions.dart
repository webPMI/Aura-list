/// Excepciones para operaciones temporales y de recurrencia en AuraList.
///
/// Este modulo define excepciones especificas para el motor de recurrencia,
/// validacion de fechas, y operaciones relacionadas con el tiempo.
///
/// Todas las excepciones extienden [AppException] para mantener consistencia
/// con el sistema de manejo de errores de la aplicacion.
library;

import 'app_exceptions.dart';

// =============================================================================
// BASE TEMPORAL EXCEPTION
// =============================================================================

/// Excepcion base para todos los errores temporales/recurrencia.
///
/// Proporciona contexto adicional especifico para operaciones de tiempo:
/// - ID de la tarea afectada
/// - Operacion que se estaba realizando
/// - Contexto de debugging estructurado
abstract class AuraTemporalException extends AppException {
  /// ID de la tarea siendo procesada (si aplica)
  final String? taskId;

  /// Operacion que se estaba realizando
  final String? operation;

  /// Datos estructurados para debugging
  final Map<String, dynamic>? debugContext;

  const AuraTemporalException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = false,
    this.taskId,
    this.operation,
    this.debugContext,
  });

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (taskId != null) buffer.write(' [taskId: $taskId]');
    if (operation != null) buffer.write(' [operation: $operation]');
    return buffer.toString();
  }
}

// =============================================================================
// INVALID RECURRENCE RULE EXCEPTION
// =============================================================================

/// Excepcion para reglas de recurrencia invalidas o malformadas.
///
/// Se lanza cuando:
/// - El formato RRULE no es valido
/// - Frecuencia no soportada
/// - Dias de semana invalidos
/// - Count o interval fuera de rango
class InvalidRecurrenceRuleException extends AuraTemporalException {
  /// La cadena RRULE que fallo (si aplica)
  final String? rruleString;

  /// Componente especifico que fallo (FREQ, BYDAY, COUNT, etc.)
  final String? failedComponent;

  const InvalidRecurrenceRuleException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    this.rruleString,
    this.failedComponent,
    super.taskId,
    super.operation,
    super.debugContext,
  });

  /// Crea una excepcion para RRULE malformada
  factory InvalidRecurrenceRuleException.malformedRule({
    required String rruleString,
    String? failedComponent,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Malformed RRULE: $rruleString${failedComponent != null ? ' (failed at: $failedComponent)' : ''}',
      userMessage: 'La regla de recurrencia no esta bien formada.',
      originalError: originalError,
      stackTrace: stackTrace,
      rruleString: rruleString,
      failedComponent: failedComponent,
      taskId: taskId,
      operation: 'parse_rrule',
    );
  }

  /// Crea una excepcion para frecuencia no soportada
  factory InvalidRecurrenceRuleException.unsupportedFrequency({
    required String frequency,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Unsupported recurrence frequency: $frequency',
      userMessage: 'Tipo de recurrencia no soportado: $frequency',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'FREQ',
      taskId: taskId,
      operation: 'validate_frequency',
    );
  }

  /// Crea una excepcion para dias invalidos (BYDAY)
  factory InvalidRecurrenceRuleException.invalidByDay({
    required String byDayValue,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid BYDAY value: $byDayValue',
      userMessage: 'Los dias seleccionados no son validos.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'BYDAY',
      taskId: taskId,
      operation: 'validate_bydays',
    );
  }

  /// Crea una excepcion para COUNT invalido
  factory InvalidRecurrenceRuleException.invalidCount({
    required dynamic countValue,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid COUNT value: $countValue (must be positive integer)',
      userMessage: 'El numero de repeticiones debe ser un numero positivo.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'COUNT',
      taskId: taskId,
      operation: 'validate_count',
    );
  }

  /// Crea una excepcion para INTERVAL invalido
  factory InvalidRecurrenceRuleException.invalidInterval({
    required dynamic intervalValue,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid INTERVAL value: $intervalValue (must be positive integer)',
      userMessage: 'El intervalo debe ser un numero positivo.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'INTERVAL',
      taskId: taskId,
      operation: 'validate_interval',
    );
  }

  /// Crea una excepcion para dias de mes invalidos (BYMONTHDAY)
  factory InvalidRecurrenceRuleException.invalidMonthDay({
    required int dayValue,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid BYMONTHDAY value: $dayValue (must be 1-31 or -1 to -31)',
      userMessage: 'El dia del mes debe estar entre 1 y 31.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'BYMONTHDAY',
      taskId: taskId,
      operation: 'validate_monthday',
    );
  }

  /// Crea una excepcion para meses invalidos (BYMONTH)
  factory InvalidRecurrenceRuleException.invalidMonth({
    required int monthValue,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid BYMONTH value: $monthValue (must be 1-12)',
      userMessage: 'El mes debe estar entre 1 y 12.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'BYMONTH',
      taskId: taskId,
      operation: 'validate_month',
    );
  }

  /// Crea una excepcion para weekPosition invalido
  factory InvalidRecurrenceRuleException.invalidWeekPosition({
    required int position,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Invalid week position: $position (must be 1-5 or -1 to -5)',
      userMessage: 'La posicion de semana debe ser entre 1-5 o -1 a -5.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'BYSETPOS',
      taskId: taskId,
      operation: 'validate_week_position',
    );
  }

  /// Crea una excepcion para lista de dias vacia
  factory InvalidRecurrenceRuleException.emptyDaysList({
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return InvalidRecurrenceRuleException(
      message: 'Empty days list for weekly/daily recurrence',
      userMessage: 'Debes seleccionar al menos un dia.',
      originalError: originalError,
      stackTrace: stackTrace,
      failedComponent: 'BYDAY',
      taskId: taskId,
      operation: 'validate_days_list',
    );
  }
}

// =============================================================================
// DATE RANGE EXCEPTION
// =============================================================================

/// Excepcion para rangos de fechas invalidos.
///
/// Se lanza cuando:
/// - Fecha de inicio es posterior a fecha de fin
/// - Fecha sugerida es posterior a deadline
/// - Fechas requeridas son null
/// - Fechas estan fuera de rangos permitidos
class DateRangeException extends AuraTemporalException {
  /// Fecha de inicio que causo el error
  final DateTime? startDate;

  /// Fecha de fin que causo el error
  final DateTime? endDate;

  /// Restriccion que fue violada
  final String? constraintViolated;

  const DateRangeException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    this.startDate,
    this.endDate,
    this.constraintViolated,
    super.taskId,
    super.operation,
    super.debugContext,
  });

  /// Crea una excepcion para inicio > fin
  factory DateRangeException.startAfterEnd({
    required DateTime startDate,
    required DateTime endDate,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return DateRangeException(
      message: 'Start date ($startDate) is after end date ($endDate)',
      userMessage: 'La fecha de inicio no puede ser despues de la fecha de fin.',
      originalError: originalError,
      stackTrace: stackTrace,
      startDate: startDate,
      endDate: endDate,
      constraintViolated: 'startDate <= endDate',
      taskId: taskId,
      operation: 'validate_date_range',
    );
  }

  /// Crea una excepcion para dueDate > deadline
  factory DateRangeException.dueDateAfterDeadline({
    required DateTime dueDate,
    required DateTime deadline,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return DateRangeException(
      message: 'Due date ($dueDate) is after hard deadline ($deadline)',
      userMessage: 'La fecha sugerida no puede ser despues de la fecha limite.',
      originalError: originalError,
      stackTrace: stackTrace,
      startDate: dueDate,
      endDate: deadline,
      constraintViolated: 'dueDate <= deadline',
      taskId: taskId,
      operation: 'validate_due_vs_deadline',
    );
  }

  /// Crea una excepcion para fecha null requerida
  factory DateRangeException.nullDate({
    required String fieldName,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return DateRangeException(
      message: 'Required date field is null: $fieldName',
      userMessage: 'La fecha $fieldName es requerida.',
      originalError: originalError,
      stackTrace: stackTrace,
      constraintViolated: '$fieldName != null',
      taskId: taskId,
      operation: 'validate_null_date',
    );
  }

  /// Crea una excepcion para fecha en el pasado (cuando no es permitido)
  factory DateRangeException.dateInPast({
    required DateTime date,
    required String fieldName,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return DateRangeException(
      message: '$fieldName ($date) is in the past',
      userMessage: 'La fecha $fieldName no puede estar en el pasado.',
      originalError: originalError,
      stackTrace: stackTrace,
      startDate: date,
      constraintViolated: '$fieldName >= today',
      taskId: taskId,
      operation: 'validate_future_date',
    );
  }

  /// Crea una excepcion para fecha demasiado lejana
  factory DateRangeException.dateTooFar({
    required DateTime date,
    required Duration maxFuture,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return DateRangeException(
      message: 'Date ($date) is more than ${maxFuture.inDays} days in the future',
      userMessage: 'La fecha no puede ser mas de ${maxFuture.inDays} dias en el futuro.',
      originalError: originalError,
      stackTrace: stackTrace,
      startDate: date,
      constraintViolated: 'date <= now + ${maxFuture.inDays} days',
      taskId: taskId,
      operation: 'validate_max_future',
    );
  }
}

// =============================================================================
// TIMEZONE EXCEPTION
// =============================================================================

/// Excepcion para errores relacionados con zonas horarias.
///
/// Se lanza cuando:
/// - Identificador de timezone invalido
/// - Ambiguedad durante transicion DST
/// - Error al convertir entre zonas horarias
class TimezoneException extends AuraTemporalException {
  /// Identificador de timezone que causo el error
  final String? timezoneId;

  /// Timezone sugerida como alternativa
  final String? suggestedTimezone;

  const TimezoneException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    this.timezoneId,
    this.suggestedTimezone,
    super.taskId,
    super.operation,
    super.debugContext,
  });

  /// Crea una excepcion para timezone desconocida
  factory TimezoneException.unknownTimezone({
    required String timezoneId,
    String? suggestedTimezone,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return TimezoneException(
      message: 'Unknown timezone identifier: $timezoneId',
      userMessage: 'La zona horaria "$timezoneId" no es valida.',
      originalError: originalError,
      stackTrace: stackTrace,
      timezoneId: timezoneId,
      suggestedTimezone: suggestedTimezone,
      taskId: taskId,
      operation: 'validate_timezone',
    );
  }

  /// Crea una excepcion para ambiguedad en transicion DST
  factory TimezoneException.dstTransitionAmbiguity({
    required DateTime dateTime,
    required String timezoneId,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return TimezoneException(
      message: 'Ambiguous time during DST transition: $dateTime in $timezoneId',
      userMessage: 'Hora ambigua durante cambio de horario. Especifica una hora diferente.',
      originalError: originalError,
      stackTrace: stackTrace,
      timezoneId: timezoneId,
      taskId: taskId,
      operation: 'handle_dst_transition',
      debugContext: {'dateTime': dateTime.toIso8601String()},
    );
  }

  /// Crea una excepcion para hora inexistente (salto DST)
  factory TimezoneException.nonExistentTime({
    required DateTime dateTime,
    required String timezoneId,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return TimezoneException(
      message: 'Non-existent time during DST spring forward: $dateTime in $timezoneId',
      userMessage: 'Esta hora no existe debido al cambio de horario.',
      originalError: originalError,
      stackTrace: stackTrace,
      timezoneId: timezoneId,
      taskId: taskId,
      operation: 'validate_dst_time',
      debugContext: {'dateTime': dateTime.toIso8601String()},
    );
  }

  /// Crea una excepcion para error de conversion
  factory TimezoneException.conversionFailed({
    required String fromTimezone,
    required String toTimezone,
    required DateTime dateTime,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return TimezoneException(
      message: 'Failed to convert $dateTime from $fromTimezone to $toTimezone',
      userMessage: 'Error al convertir la hora entre zonas horarias.',
      originalError: originalError,
      stackTrace: stackTrace,
      timezoneId: fromTimezone,
      suggestedTimezone: toTimezone,
      taskId: taskId,
      operation: 'convert_timezone',
      debugContext: {'dateTime': dateTime.toIso8601String()},
    );
  }
}

// =============================================================================
// OCCURRENCE CALCULATION EXCEPTION
// =============================================================================

/// Excepcion para errores al calcular ocurrencias de recurrencia.
///
/// Se lanza cuando:
/// - El calculo de nextOccurrence falla
/// - Se detecta un loop infinito
/// - El resultado excede limites
/// - Resultado invalido o inesperado
class OccurrenceCalculationException extends AuraTemporalException {
  /// Tipo de recurrencia (daily, weekly, monthly, yearly)
  final String? recurrenceType;

  /// Fecha de referencia usada en el calculo
  final DateTime? referenceDate;

  /// Numero de intentos realizados
  final int? attemptCount;

  /// Limite maximo de iteraciones
  final int? maxIterations;

  const OccurrenceCalculationException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    this.recurrenceType,
    this.referenceDate,
    this.attemptCount,
    this.maxIterations,
    super.taskId,
    super.operation,
    super.debugContext,
  });

  /// Crea una excepcion para posible loop infinito
  factory OccurrenceCalculationException.infiniteLoop({
    required String recurrenceType,
    required DateTime referenceDate,
    int? maxIterations,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return OccurrenceCalculationException(
      message: 'Possible infinite loop detected for $recurrenceType at $referenceDate (max iterations: ${maxIterations ?? "unknown"})',
      userMessage: 'No se pudo calcular la proxima ocurrencia. Verifica la regla de recurrencia.',
      originalError: originalError,
      stackTrace: stackTrace,
      recurrenceType: recurrenceType,
      referenceDate: referenceDate,
      maxIterations: maxIterations,
      taskId: taskId,
      operation: 'calculate_next_occurrence',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para deadline excedido
  factory OccurrenceCalculationException.deadlineExceeded({
    required DateTime calculatedDate,
    required DateTime deadline,
    required String recurrenceType,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return OccurrenceCalculationException(
      message: 'Next occurrence ($calculatedDate) exceeds deadline ($deadline) for $recurrenceType',
      userMessage: 'La proxima ocurrencia estaria despues de la fecha limite.',
      originalError: originalError,
      stackTrace: stackTrace,
      recurrenceType: recurrenceType,
      referenceDate: calculatedDate,
      taskId: taskId,
      operation: 'validate_occurrence_deadline',
      isRetryable: false,
      debugContext: {'deadline': deadline.toIso8601String()},
    );
  }

  /// Crea una excepcion para resultado invalido
  factory OccurrenceCalculationException.invalidResult({
    required dynamic resultValue,
    required String recurrenceType,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return OccurrenceCalculationException(
      message: 'Invalid calculation result for $recurrenceType: $resultValue (type: ${resultValue.runtimeType})',
      userMessage: 'Resultado invalido en calculo de recurrencia.',
      originalError: originalError,
      stackTrace: stackTrace,
      recurrenceType: recurrenceType,
      taskId: taskId,
      operation: 'validate_calculation_result',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para regla agotada (sin mas ocurrencias)
  factory OccurrenceCalculationException.ruleExhausted({
    required String recurrenceType,
    required DateTime lastOccurrence,
    String? reason,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return OccurrenceCalculationException(
      message: 'Recurrence rule exhausted for $recurrenceType. Last: $lastOccurrence${reason != null ? '. Reason: $reason' : ''}',
      userMessage: 'La regla de recurrencia ha terminado.',
      originalError: originalError,
      stackTrace: stackTrace,
      recurrenceType: recurrenceType,
      referenceDate: lastOccurrence,
      taskId: taskId,
      operation: 'check_rule_exhaustion',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para error de calculo interno
  factory OccurrenceCalculationException.calculationFailed({
    required String recurrenceType,
    required DateTime referenceDate,
    required String reason,
    dynamic originalError,
    StackTrace? stackTrace,
    String? taskId,
  }) {
    return OccurrenceCalculationException(
      message: 'Failed to calculate next occurrence for $recurrenceType from $referenceDate: $reason',
      userMessage: 'Error al calcular la proxima ocurrencia.',
      originalError: originalError,
      stackTrace: stackTrace,
      recurrenceType: recurrenceType,
      referenceDate: referenceDate,
      taskId: taskId,
      operation: 'calculate_next_occurrence',
      isRetryable: true,
    );
  }
}

// =============================================================================
// RECURRENCE SYNC EXCEPTION
// =============================================================================

/// Excepcion para errores de sincronizacion de recurrencia.
///
/// Se lanza cuando hay conflictos o errores al sincronizar
/// tareas recurrentes entre dispositivos.
class RecurrenceSyncException extends AuraTemporalException {
  /// ID de la tarea padre
  final String? parentTaskId;

  /// Fecha de la instancia afectada
  final DateTime? instanceDate;

  /// Tipo de conflicto
  final String? conflictType;

  const RecurrenceSyncException({
    required super.message,
    super.userMessage,
    super.originalError,
    super.stackTrace,
    super.isRetryable = true,
    this.parentTaskId,
    this.instanceDate,
    this.conflictType,
    super.taskId,
    super.operation,
    super.debugContext,
  });

  /// Crea una excepcion para conflicto de estado
  factory RecurrenceSyncException.stateConflict({
    required String parentTaskId,
    required DateTime instanceDate,
    required String localState,
    required String remoteState,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RecurrenceSyncException(
      message: 'State conflict for $parentTaskId on $instanceDate: local=$localState, remote=$remoteState',
      userMessage: 'Conflicto de estado. Se usara la version mas reciente.',
      originalError: originalError,
      stackTrace: stackTrace,
      parentTaskId: parentTaskId,
      instanceDate: instanceDate,
      conflictType: 'state_conflict',
      operation: 'sync_instance',
      debugContext: {
        'localState': localState,
        'remoteState': remoteState,
      },
    );
  }

  /// Crea una excepcion para padre no encontrado
  factory RecurrenceSyncException.parentNotFound({
    required String parentTaskId,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RecurrenceSyncException(
      message: 'Parent task not found: $parentTaskId',
      userMessage: 'La tarea padre no existe.',
      originalError: originalError,
      stackTrace: stackTrace,
      parentTaskId: parentTaskId,
      conflictType: 'parent_not_found',
      operation: 'find_parent',
      isRetryable: false,
    );
  }

  /// Crea una excepcion para regla modificada durante sync
  factory RecurrenceSyncException.ruleModifiedDuringSync({
    required String parentTaskId,
    required DateTime modifiedAt,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return RecurrenceSyncException(
      message: 'Parent rule was modified during sync: $parentTaskId at $modifiedAt',
      userMessage: 'La regla fue modificada. Actualizando...',
      originalError: originalError,
      stackTrace: stackTrace,
      parentTaskId: parentTaskId,
      conflictType: 'rule_modified',
      operation: 'sync_rule',
      isRetryable: true,
      debugContext: {'modifiedAt': modifiedAt.toIso8601String()},
    );
  }
}
