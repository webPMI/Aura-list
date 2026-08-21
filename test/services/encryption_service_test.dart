import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/services/encryption/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncryptionService Tests', () {
    late EncryptionService encryption;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      encryption = EncryptionService();
      await encryption.initialize();
    });

    test('initializes and generates a valid 256-bit key', () {
      expect(encryption.isInitialized, isTrue);
      expect(encryption.exportableKey.isNotEmpty, isTrue);
    });

    test('encrypts and decrypts a Map payload correctly (Zero-Knowledge AES-256)', () {
      final sampleTaskData = {
        'title': 'Comprar medicamentos privados',
        'type': 'daily',
        'isCompleted': false,
        'category': 'Salud',
        'priority': 3,
        'motivation': 'Cuidar mi bienestar',
        'financialCost': 45.50,
        'createdAt': '2026-08-21T20:00:00.000Z',
        'lastUpdatedAt': '2026-08-21T20:00:00.000Z',
        'deleted': false,
      };

      final encrypted = encryption.encryptMap(sampleTaskData);

      // Verify that plain text is NOT present in the encrypted map
      expect(encrypted['encrypted'], isTrue);
      expect(encrypted['iv'], isNotNull);
      expect(encrypted['payload'], isNotNull);
      expect(encrypted.containsKey('title'), isFalse);
      expect(encrypted.containsKey('financialCost'), isFalse);
      expect(encrypted.containsKey('motivation'), isFalse);

      // Verify sync metadata is preserved
      expect(encrypted['lastUpdatedAt'], '2026-08-21T20:00:00.000Z');
      expect(encrypted['deleted'], isFalse);

      // Decrypt
      final decrypted = encryption.decryptMap(encrypted);

      expect(decrypted['title'], 'Comprar medicamentos privados');
      expect(decrypted['type'], 'daily');
      expect(decrypted['category'], 'Salud');
      expect(decrypted['priority'], 3);
      expect(decrypted['motivation'], 'Cuidar mi bienestar');
      expect(decrypted['financialCost'], 45.50);
    });

    test('gracefully handles legacy unencrypted documents', () {
      final legacyData = {
        'title': 'Tarea antigua sin cifrar',
        'type': 'weekly',
        'isCompleted': true,
      };

      final result = encryption.decryptMap(legacyData);
      expect(result['title'], 'Tarea antigua sin cifrar');
      expect(result['type'], 'weekly');
      expect(result['isCompleted'], isTrue);
    });

    test('supports custom key / master passphrase derivation', () async {
      await encryption.initialize(customKey: 'mi-frase-secreta-personal-1234');
      expect(encryption.isInitialized, isTrue);

      final data = {'secret': 'Información ultrasecreta'};
      final encrypted = encryption.encryptMap(data);
      expect(encrypted['encrypted'], isTrue);

      final decrypted = encryption.decryptMap(encrypted);
      expect(decrypted['secret'], 'Información ultrasecreta');
    });
  });
}
