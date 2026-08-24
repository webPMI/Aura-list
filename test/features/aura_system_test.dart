import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/features/aura/models/aura_state.dart';
import 'package:checklist_app/features/aura/services/aura_service.dart';
import 'package:checklist_app/features/aura/providers/aura_provider.dart';
import 'package:checklist_app/features/aura/widgets/aura_energy_card.dart';
import 'package:checklist_app/features/aura/widgets/aura_sanctuary_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Aura System Unit Tests', () {
    test('AuraState ranks and levels calculate correctly', () {
      const state1 = AuraState(totalPoints: 50, availablePoints: 50);
      expect(state1.level, 1);
      expect(state1.rank, AuraRank.novice);
      expect(state1.pointsToNextLevel, 50);

      const state2 = AuraState(totalPoints: 350, availablePoints: 350);
      expect(state2.level, 4);
      expect(state2.rank, AuraRank.explorer);

      const state3 = AuraState(totalPoints: 1200, availablePoints: 1200);
      expect(state3.level, 13);
      expect(state3.rank, AuraRank.guardian);

      const state4 = AuraState(totalPoints: 6000, availablePoints: 6000);
      expect(state4.level, 61);
      expect(state4.rank, AuraRank.celestialMaster);
    });

    test('AuraService adds points, updates recent activity and saves', () async {
      final service = AuraService();
      await service.load();

      final initialPoints = service.state.availablePoints;
      await service.addPoints(25, reason: 'Tarea completada');

      expect(service.state.availablePoints, initialPoints + 25);
      expect(service.state.totalPoints, initialPoints + 25);
      expect(service.state.recentActivity.first, contains('Tarea completada (+25 pts)'));
    });

    test('AuraService buys streak shield and checks balance', () async {
      final service = AuraService();
      await service.load();

      // Ensure enough points
      await service.addPoints(100, reason: 'Bonus');
      final beforePoints = service.state.availablePoints;
      final beforeShields = service.state.streakShields;

      final success = await service.buyStreakShield(cost: 100);
      expect(success, isTrue);
      expect(service.state.availablePoints, beforePoints - 100);
      expect(service.state.streakShields, beforeShields + 1);

      // Spend all points and verify buying fails
      await service.spendPoints(service.state.availablePoints, reason: 'Reset');
      final fail = await service.buyStreakShield(cost: 100);
      expect(fail, isFalse);
    });

    test('AuraService unlocks cosmic themes', () async {
      final service = AuraService();
      await service.load();

      await service.addPoints(500, reason: 'Bonus');
      final success = await service.unlockTheme(
        'cosmic_purple',
        cost: 300,
        themeName: 'Nebulosa Púrpura',
      );

      expect(success, isTrue);
      expect(service.state.unlockedThemes.contains('cosmic_purple'), isTrue);
    });
  });

  group('Aura System Widget Tests', () {
    testWidgets('AuraEnergyCard renders rank, level and opens sanctuary sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AuraEnergyCard(),
            ),
          ),
        ),
      );

      // Verify card contents
      expect(find.text('Iniciado del Foco'), findsOneWidget);
      expect(find.textContaining('Nivel 1'), findsWidgets);
      expect(find.textContaining('pts'), findsWidgets);

      // Tap the points/sanctuary button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Santuario sheet is opened
      expect(find.text('Santuario de Aura'), findsOneWidget);
      expect(find.text('Escudo de Racha'), findsOneWidget);
      expect(find.text('Temas Cósmicos'), findsOneWidget);
    });
  });
}
