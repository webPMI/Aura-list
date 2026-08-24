import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/widgets/ads/discrete_ad_banner.dart';
import 'package:checklist_app/widgets/ads/rewarded_energy_card.dart';
import 'package:checklist_app/providers/ad_provider.dart';

void main() {
  group('Ads & Monetization Widgets Tests', () {
    testWidgets('DiscreteAdBanner renders properly for free users and can be dismissed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DiscreteAdBanner(),
            ),
          ),
        ),
      );

      // Verify that it renders the sponsored label and title
      expect(find.text('Patrocinado'), findsOneWidget);
      expect(find.text('¿Creando tu propio proyecto?'), findsOneWidget);
      expect(find.text('Ver más'), findsOneWidget);

      // Tap the close button to dismiss
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Should be dismissed
      expect(find.text('Patrocinado'), findsNothing);
    });

    testWidgets('DiscreteAdBanner is hidden when user is Pro', (tester) async {
      final container = ProviderContainer(
        overrides: [
          isProUserProvider.overrideWith((ref) => true),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DiscreteAdBanner(),
            ),
          ),
        ),
      );

      expect(find.text('Patrocinado'), findsNothing);
    });

    testWidgets('RewardedEnergyCard renders properly and triggers reward callback on tap', (tester) async {
      bool rewarded = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RewardedEnergyCard(
                onEnergyEarned: () {
                  rewarded = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Recarga de Energía Aura'), findsOneWidget);
      expect(find.text('Ver'), findsOneWidget);

      // Tap 'Ver'
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();

      expect(rewarded, isTrue);
      expect(find.textContaining('Energía Aura desbloqueada'), findsOneWidget);
    });
  });
}
