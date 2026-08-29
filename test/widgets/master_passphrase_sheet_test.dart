import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/widgets/auth/master_passphrase_sheet.dart';
import 'package:checklist_app/services/encryption/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MasterPassphraseSheet Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await EncryptionService().initialize();
    });

    testWidgets('renders MasterPassphraseSheet and allows setting custom passphrase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MasterPassphraseSheet(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Tus Notas Bajo Llave'), findsOneWidget);
      expect(find.text('Crear mi Llave Secreta Personal'), findsOneWidget);
      expect(find.text('Copiar Clave'), findsOneWidget);

      // Tap on set master passphrase
      await tester.tap(find.text('Crear mi Llave Secreta Personal'));
      await tester.pump();

      expect(find.text('Elige tu Contraseña Maestra Personal'), findsOneWidget);
      expect(find.text('Guardar Contraseña'), findsOneWidget);

      // Try typing mismatching passwords
      await tester.enterText(find.byType(TextField).first, 'mi-clave-123');
      await tester.enterText(find.byType(TextField).last, 'otra-clave-distinta');
      await tester.tap(find.text('Guardar Contraseña'));
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

      // Type matching password
      await tester.enterText(find.byType(TextField).last, 'mi-clave-123');
      await tester.tap(find.text('Guardar Contraseña'));
      await tester.pump();

      expect(EncryptionService().hasCustomPassphrase, isTrue);
    });
  });
}
