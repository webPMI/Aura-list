import 'package:flutter/material.dart';

class TimeUtils {
  /// Convert TimeOfDay to minutes since midnight
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Convert minutes since midnight to TimeOfDay
  static TimeOfDay minutesToTimeOfDay(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return TimeOfDay(hour: hours, minute: mins);
  }

  /// Format minutes since midnight as HH:mm string
  static String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Format TimeOfDay as HH:mm string
  static String formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
