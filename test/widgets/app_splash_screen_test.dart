import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/widgets/splash/app_splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSplashScreen Tests', () {
    testWidgets('renders AppSplashScreen with logo, security badge and progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppSplashScreen(),
        ),
      );

      expect(find.text('AuraList'), findsOneWidget);
      expect(find.text('Cifrado Zero-Knowledge AES-256'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Toca para ver otro consejo'), findsOneWidget);

      // Advance time to verify step progress
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Verificando cifrado militar AES-256...'), findsOneWidget);

      // Tap on tips box to switch tip interactively
      await tester.tap(find.text('Toca para ver otro consejo'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Toca para ver otro consejo'), findsOneWidget);
    });
  });
}
