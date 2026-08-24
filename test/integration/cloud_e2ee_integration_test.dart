import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/features/finance/models/transaction.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/models/recurring_transaction.dart';
import 'package:checklist_app/models/recurrence_rule.dart';
import 'package:checklist_app/services/encryption/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud E2EE Zero-Knowledge Integration Tests', () {
    late EncryptionService encryption;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      encryption = EncryptionService();
      await encryption.initialize();
    });

    test('Full Task cloud encryption round-trip preserves all fields while concealing plaintext', () {
      final originalTask = Task(
        firestoreId: 'cloud_task_123',
        title: 'Revisión Médica Confidencial',
        type: 'daily',
        isCompleted: false,
        category: 'Salud Privada',
        priority: 3,
        motivation: 'Cuidar de mi salud y bienestar personal',
        reward: 'Tarde libre',
        financialCost: 120.50,
        financialBenefit: 200.0,
        createdAt: DateTime(2026, 8, 24, 10, 0),
        lastUpdatedAt: DateTime(2026, 8, 24, 10, 30),
      );

      // 1. Serialize and encrypt for Firestore
      final rawFirestoreData = originalTask.toFirestore();
      final encryptedCloudData = encryption.encryptMap(rawFirestoreData);

      // 2. Assert cloud payload is fully encrypted
      expect(encryptedCloudData['encrypted'], isTrue);
      expect(encryptedCloudData['payload'], isA<String>());
      expect(encryptedCloudData['iv'], isA<String>());
      expect(encryptedCloudData.containsKey('title'), isFalse);
      expect(encryptedCloudData.containsKey('category'), isFalse);
      expect(encryptedCloudData.containsKey('motivation'), isFalse);
      expect(encryptedCloudData.containsKey('financialCost'), isFalse);

      // 3. Decrypt and reconstruct Task from cloud
      final decryptedCloudData = encryption.decryptMap(encryptedCloudData);
      final restoredTask = Task.fromFirestore('cloud_task_123', decryptedCloudData);

      // 4. Verify exact equality of all properties
      expect(restoredTask.title, originalTask.title);
      expect(restoredTask.type, originalTask.type);
      expect(restoredTask.category, originalTask.category);
      expect(restoredTask.priority, originalTask.priority);
      expect(restoredTask.motivation, originalTask.motivation);
      expect(restoredTask.reward, originalTask.reward);
      expect(restoredTask.financialCost, originalTask.financialCost);
      expect(restoredTask.financialBenefit, originalTask.financialBenefit);
    });

    test('Full Note with Checklist cloud encryption round-trip', () {
      final originalNote = Note(
        firestoreId: 'cloud_note_456',
        title: 'Ideas de Negocio e Inversión',
        content: 'Presupuesto inicial para el proyecto secreto',
        color: '#FF6B6B',
        tags: ['Inversión', 'Confidencial'],
        checklist: [
          ChecklistItem(id: 'chk_1', text: 'Contactar asesor legal', isCompleted: true),
          ChecklistItem(id: 'chk_2', text: 'Firmar acuerdo de confidencialidad', isCompleted: false),
        ],
        isPinned: true,
        createdAt: DateTime(2026, 8, 24, 11, 0),
        updatedAt: DateTime(2026, 8, 24, 11, 15),
      );

      // 1. Encrypt for Firestore
      final encryptedCloudData = encryption.encryptMap(originalNote.toFirestore());

      // 2. Verify plaintext isolation
      expect(encryptedCloudData['encrypted'], isTrue);
      expect(encryptedCloudData.containsKey('title'), isFalse);
      expect(encryptedCloudData.containsKey('content'), isFalse);
      expect(encryptedCloudData.containsKey('checklist'), isFalse);

      // 3. Decrypt and reconstruct
      final decryptedCloudData = encryption.decryptMap(encryptedCloudData);
      final restoredNote = Note.fromFirestore('cloud_note_456', decryptedCloudData);

      expect(restoredNote.title, originalNote.title);
      expect(restoredNote.content, originalNote.content);
      expect(restoredNote.color, originalNote.color);
      expect(restoredNote.tags, originalNote.tags);
      expect(restoredNote.isPinned, originalNote.isPinned);
      expect(restoredNote.checklist.length, 2);
      expect(restoredNote.checklist[0].text, 'Contactar asesor legal');
      expect(restoredNote.checklist[0].isCompleted, isTrue);
      expect(restoredNote.checklist[1].text, 'Firmar acuerdo de confidencialidad');
      expect(restoredNote.checklist[1].isCompleted, isFalse);
    });

    test('Full Finance Transaction cloud encryption round-trip', () {
      final originalTx = Transaction(
        id: 'tx_priv_789',
        title: 'Pago de Consultoría Privada',
        amount: -1500.00,
        date: DateTime(2026, 8, 24, 14, 0),
        categoryId: 'cat_legal_1',
        type: FinanceCategoryType.expense,
        note: 'Factura número 2026-X84',
        createdAt: DateTime(2026, 8, 24, 14, 0),
        lastUpdatedAt: DateTime(2026, 8, 24, 14, 5),
      );

      // 1. Encrypt
      final encryptedData = encryption.encryptMap(originalTx.toFirestore());

      expect(encryptedData['encrypted'], isTrue);
      expect(encryptedData.containsKey('title'), isFalse);
      expect(encryptedData.containsKey('amount'), isFalse);
      expect(encryptedData.containsKey('note'), isFalse);

      // 2. Decrypt
      final decryptedData = encryption.decryptMap(encryptedData);
      final restoredTx = Transaction.fromFirestore('tx_priv_789', decryptedData);

      expect(restoredTx.title, originalTx.title);
      expect(restoredTx.amount, originalTx.amount);
      expect(restoredTx.categoryId, originalTx.categoryId);
      expect(restoredTx.type, originalTx.type);
      expect(restoredTx.note, originalTx.note);
    });

    test('Full Recurring Transaction cloud encryption round-trip', () {
      final originalRecurring = RecurringTransaction(
        id: 'rec_tx_999',
        title: 'Alquiler Departamento',
        amount: 850.00,
        categoryId: 'cat_vivienda',
        type: FinanceCategoryType.expense,
        recurrence: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime(2026, 8, 24),
          byMonthDays: [5],
        ),
        note: 'Transferencia automática a propietario',
        autoGenerate: true,
        createdAt: DateTime(2026, 8, 24, 15, 0),
      );

      // 1. Encrypt
      final encryptedData = encryption.encryptMap(originalRecurring.toFirestore());

      expect(encryptedData['encrypted'], isTrue);
      expect(encryptedData.containsKey('title'), isFalse);
      expect(encryptedData.containsKey('amount'), isFalse);

      // 2. Decrypt
      final decryptedData = encryption.decryptMap(encryptedData);
      final restoredRecurring = RecurringTransaction.fromFirestore('rec_tx_999', decryptedData);

      expect(restoredRecurring.title, originalRecurring.title);
      expect(restoredRecurring.amount, originalRecurring.amount);
      expect(restoredRecurring.note, originalRecurring.note);
      expect(restoredRecurring.recurrence.frequency, RecurrenceFrequency.monthly);
      expect(restoredRecurring.recurrence.byMonthDays, [5]);
    });

    test('Different Master Passphrases cannot decrypt each other (Zero-Knowledge Isolation)', () async {
      // User A encrypts
      await encryption.setMasterPassphrase('usuarioA-clave-super-segura-1');
      final secretData = {'salary': 5000, 'accountNumber': 'ES9121000418450200051332'};
      final encryptedByA = encryption.encryptMap(secretData);

      // User B with another passphrase tries to decrypt
      final userBEncryption = EncryptionService();
      await userBEncryption.setMasterPassphrase('usuarioB-clave-totalmente-distinta-2');

      // Attempting to decrypt with wrong key fails gracefully and does not expose plain data
      final failedDecryption = userBEncryption.decryptMap(encryptedByA);
      expect(failedDecryption.containsKey('salary'), isFalse);
      expect(failedDecryption.containsKey('accountNumber'), isFalse);
      expect(failedDecryption['encrypted'], isTrue); // remains raw encrypted payload
    });
  });
}
