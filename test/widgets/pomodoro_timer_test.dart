import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/widgets/pomodoro_timer_card.dart';

void main() {
  group('PomodoroTimerCard Tests', () {
    testWidgets('renders Pomodoro timer collapsed and expands on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroTimerCard(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Temporizador Pomodoro'), findsOneWidget);
      expect(find.textContaining('Enfoque'), findsOneWidget);
      expect(find.text('25:00'), findsNothing); // Initially collapsed

      // Tap to expand
      await tester.tap(find.text('Temporizador Pomodoro'));
      await tester.pump();

      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Iniciar'), findsOneWidget);
      expect(find.text('Reiniciar'), findsOneWidget);
      expect(find.text('Descanso (5m)'), findsOneWidget);
      expect(find.text('Descanso Largo (15m)'), findsOneWidget);
    });

    testWidgets('switches mode to short break and updates time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroTimerCard(),
          ),
        ),
      );

      await tester.pump();

      // Expand
      await tester.tap(find.text('Temporizador Pomodoro'));
      await tester.pump();

      // Tap on Short Break chip
      await tester.tap(find.text('Descanso (5m)'));
      await tester.pump();

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('DESCANSO'), findsOneWidget);
    });
  });
}
