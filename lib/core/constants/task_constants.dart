import 'package:flutter/material.dart';

class TaskConstants {
  static const List<String> categories = [
    'Personal',
    'Trabajo',
    'Hogar',
    'Salud',
    'Otros',
  ];

  static const List<String> priorityLabels = ['Baja', 'Media', 'Alta'];

  static const List<Color> priorityColors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  static Color getPriorityColor(int priority) {
    return priorityColors[priority.clamp(0, 2)];
  }

  static String getPriorityLabel(int priority) {
    return priorityLabels[priority.clamp(0, 2)];
  }

  static const List<(String, String, IconData)> taskTypes = [
    ('daily', 'Diaria', Icons.wb_sunny_outlined),
    ('weekly', 'Semanal', Icons.calendar_view_week_outlined),
    ('monthly', 'Mensual', Icons.calendar_month_outlined),
    ('yearly', 'Anual', Icons.event_outlined),
    ('once', 'Única', Icons.push_pin_outlined),
  ];

  static String getTaskTypeLabel(String type) {
    for (final taskType in taskTypes) {
      if (taskType.$1 == type) return taskType.$2;
    }
    return 'Tarea';
  }

  static IconData getTaskTypeIcon(String type) {
    for (final taskType in taskTypes) {
      if (taskType.$1 == type) return taskType.$3;
    }
    return Icons.task_outlined;
  }
}
