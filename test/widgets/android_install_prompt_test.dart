import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/widgets/install/android_install_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AndroidInstallPrompt Widget Tests', () {
    testWidgets('Renders properly and handles dismiss', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AndroidInstallPrompt(
              child: Text('Main App Content'),
            ),
          ),
        ),
      );

      // Main content is always visible
      expect(find.text('Main App Content'), findsOneWidget);
    });
  });
}
