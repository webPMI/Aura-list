import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/widgets/task_list.dart';

void main() {
  group('TaskList Unified View Tests', () {
    testWidgets('renders empty state when no tasks are present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskList(
                type: 'all',
                filteredTasks: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Tu lista de tareas está vacía'), findsOneWidget);
    });

    testWidgets('renders tasks grouped into sections and filters correctly', (tester) async {
      final now = DateTime.now();
      final List<Task> sampleTasks = [
        Task(
          title: 'Tarea Vencida',
          type: 'once',
          createdAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 2)),
          priority: 2,
        ),
        Task(
          title: 'Tarea Para Hoy',
          type: 'daily',
          createdAt: now,
          dueDate: now,
          priority: 1,
        ),
        Task(
          title: 'Tarea Futura',
          type: 'once',
          createdAt: now,
          dueDate: now.add(const Duration(days: 30)),
          priority: 0,
        ),
        Task(
          title: 'Tarea Completada',
          type: 'daily',
          createdAt: now,
          isCompleted: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TaskList(
                type: 'all',
                filteredTasks: sampleTasks,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Check chips and counts
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Tarea Vencida'), findsOneWidget);
      expect(find.text('Tarea Para Hoy'), findsOneWidget);
      expect(find.text('Tarea Futura'), findsOneWidget);

      // Section headers
      expect(find.text('Vencidas'), findsOneWidget);
      expect(find.text('Para Hoy'), findsOneWidget);
      expect(find.text('Más Adelante'), findsOneWidget);
      expect(find.textContaining('Completadas (1)'), findsOneWidget);

      // Tap on 'Hoy' chip
      await tester.tap(find.text('Hoy'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tarea Para Hoy'), findsOneWidget);
      expect(find.text('Tarea Futura'), findsNothing);

      // Tap on 'Alta' chip
      await tester.tap(find.text('Alta').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tarea Vencida'), findsOneWidget);
      expect(find.text('Tarea Para Hoy'), findsNothing);
      expect(find.text('Tarea Futura'), findsNothing);
    });
  });
}
