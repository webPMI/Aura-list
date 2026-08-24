import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/widgets/splash/app_splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSplashScreen Tests', () {
    testWidgets('renders AppSplashScreen with logo, security badge and motivational quotes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppSplashScreen(),
        ),
      );

      expect(find.text('AuraList'), findsOneWidget);
      expect(find.text('100% Privado • Cifrado AES-256 E2EE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Toca aquí para recargar energía positiva'), findsOneWidget);

      // Advance time to verify step progress
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('🔐 Blindando tus datos con cifrado militar AES-256...'), findsOneWidget);

      // Tap on energy card to charge energy and switch quote
      await tester.tap(find.text('Toca aquí para recargar energía positiva'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('⚡ x1'), findsOneWidget);
    });
  });
}
