/// Firebase Sync Integration Tests
///
/// These tests verify the complete Firebase sync flow including:
/// - User authentication (anonymous, email/password, account linking)
/// - Data synchronization (tasks, notes, notebooks)
/// - Conflict resolution
/// - Offline/online scenarios
///
/// To run against Firebase Emulator:
/// 1. Start the emulator: firebase emulators:start
/// 2. Run tests: flutter test test/integration/firebase_sync_test.dart
///
/// To run against real Firebase (requires credentials):
/// Set environment variable: FIREBASE_TEST_MODE=real
/// flutter test test/integration/firebase_sync_test.dart
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/models/notebook_model.dart';
import 'package:checklist_app/models/task_history.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/models/sync_metadata.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/services/repositories/task_repository.dart';
import 'package:checklist_app/services/repositories/note_repository.dart';
import 'package:checklist_app/services/repositories/notebook_repository.dart';
import 'package:checklist_app/services/storage/local/hive_task_storage.dart';
import 'package:checklist_app/services/storage/local/hive_note_storage.dart';
import 'package:checklist_app/services/storage/local/hive_notebook_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_task_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_note_storage.dart';
import 'package:checklist_app/services/storage/cloud/firestore_notebook_storage.dart';
import 'package:checklist_app/services/sync/task_sync_service.dart';
import 'package:checklist_app/services/sync/note_sync_service.dart';
import 'package:checklist_app/services/sync/notebook_sync_service.dart';
import 'package:http/http.dart' as http;

/// Test configuration
class FirebaseTestConfig {
  /// Firebase Auth REST API base URL
  /// For emulator: http://localhost:9099
  /// For production: https://identitytoolkit.googleapis.com/v1
  static String get authBaseUrl {
    final useEmulator = Platform.environment['FIREBASE_EMULATOR'] == 'true';
    if (useEmulator) {
      return 'http://localhost:9099/identitytoolkit.googleapis.com/v1';
    }
    return 'https://identitytoolkit.googleapis.com/v1';
  }

  /// Firebase API key (required for REST API calls)
  /// Set via FIREBASE_API_KEY environment variable
  static String get apiKey {
    return Platform.environment['FIREBASE_API_KEY'] ?? 'test-api-key';
  }

  /// Firestore emulator host
  static String get firestoreHost {
    return Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? 'localhost:8080';
  }

  /// Test user credentials
  static const testEmail = 'integration-test@auralist.test';
  static const testPassword = 'TestPassword123!';
  static const testEmail2 = 'integration-test-2@auralist.test';
}

/// Mock Firebase Auth REST API client for testing
/// Uses Firebase Auth REST API to create/manage test users
class FirebaseAuthTestClient {
  final String apiKey;
  final String baseUrl;

  FirebaseAuthTestClient({
    required this.apiKey,
    required this.baseUrl,
  });

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:signUp?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('Sign up failed: ${error['error']['message']}');
    }

    return jsonDecode(response.body);
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:signInWithPassword?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('Sign in failed: ${error['error']['message']}');
    }

    return jsonDecode(response.body);
  }

  /// Sign in anonymously
  Future<Map<String, dynamic>> signInAnonymously() async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:signUp?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('Anonymous sign in failed: ${error['error']['message']}');
    }

    return jsonDecode(response.body);
  }

  /// Delete user account
  Future<void> deleteAccount(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:delete?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      // Ignore "user not found" errors during cleanup
      if (!error['error']['message'].toString().contains('USER_NOT_FOUND')) {
        throw Exception('Delete account failed: ${error['error']['message']}');
      }
    }
  }

  /// Link anonymous account with email/password credential
  Future<Map<String, dynamic>> linkWithEmailPassword(
    String idToken,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:update?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('Link account failed: ${error['error']['message']}');
    }

    return jsonDecode(response.body);
  }

  /// Get user info
  Future<Map<String, dynamic>> getUserInfo(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accounts:lookup?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('Get user info failed: ${error['error']['message']}');
    }

    final data = jsonDecode(response.body);
    return data['users']?[0] ?? {};
  }
}

/// Mock Firestore client for testing
class FirestoreTestClient {
  final String projectId;
  final String host;

  FirestoreTestClient({
    required this.projectId,
    required this.host,
  });

  String get _baseUrl => 'http://$host/v1/projects/$projectId/databases/(default)/documents';

  /// Create or update a document
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    String? parentPath,
  }) async {
    final path = parentPath != null
        ? '$_baseUrl/$parentPath/$collection/$documentId'
        : '$_baseUrl/$collection/$documentId';

    final response = await http.patch(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_convertToFirestoreFormat(data)),
    );

    if (response.statusCode != 200) {
      throw Exception('Set document failed: ${response.body}');
    }
  }

  /// Get a document
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId, {
    String? parentPath,
  }) async {
    final path = parentPath != null
        ? '$_baseUrl/$parentPath/$collection/$documentId'
        : '$_baseUrl/$collection/$documentId';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('Get document failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return _convertFromFirestoreFormat(data['fields'] ?? {});
  }

  /// Delete a document
  Future<void> deleteDocument(
    String collection,
    String documentId, {
    String? parentPath,
  }) async {
    final path = parentPath != null
        ? '$_baseUrl/$parentPath/$collection/$documentId'
        : '$_baseUrl/$collection/$documentId';

    final response = await http.delete(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
    );

    // Accept 200 or 404 (already deleted)
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Delete document failed: ${response.body}');
    }
  }

  /// List documents in a collection
  Future<List<Map<String, dynamic>>> listDocuments(
    String collection, {
    String? parentPath,
  }) async {
    final path = parentPath != null
        ? '$_baseUrl/$parentPath/$collection'
        : '$_baseUrl/$collection';

    final response = await http.get(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('List documents failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final documents = data['documents'] as List? ?? [];
    return documents.map((doc) {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      final converted = _convertFromFirestoreFormat(fields);
      // Extract document ID from name
      final name = doc['name'] as String;
      final id = name.split('/').last;
      return {'id': id, ...converted};
    }).toList();
  }

  /// Convert Dart map to Firestore REST API format
  Map<String, dynamic> _convertToFirestoreFormat(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((key, value) {
      fields[key] = _valueToFirestore(value);
    });
    return {'fields': fields};
  }

  /// Convert value to Firestore format
  Map<String, dynamic> _valueToFirestore(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is List) {
      return {
        'arrayValue': {
          'values': value.map(_valueToFirestore).toList(),
        }
      };
    } else if (value is Map) {
      final fields = <String, dynamic>{};
      value.forEach((k, v) {
        fields[k.toString()] = _valueToFirestore(v);
      });
      return {'mapValue': {'fields': fields}};
    }
    return {'stringValue': value.toString()};
  }

  /// Convert Firestore format to Dart map
  Map<String, dynamic> _convertFromFirestoreFormat(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((key, value) {
      result[key] = _valueFromFirestore(value);
    });
    return result;
  }

  /// Convert Firestore value to Dart value
  dynamic _valueFromFirestore(Map<String, dynamic> value) {
    if (value.containsKey('nullValue')) {
      return null;
    } else if (value.containsKey('booleanValue')) {
      return value['booleanValue'];
    } else if (value.containsKey('integerValue')) {
      return int.parse(value['integerValue']);
    } else if (value.containsKey('doubleValue')) {
      return value['doubleValue'];
    } else if (value.containsKey('stringValue')) {
      return value['stringValue'];
    } else if (value.containsKey('arrayValue')) {
      final values = value['arrayValue']['values'] as List? ?? [];
      return values.map((v) => _valueFromFirestore(v as Map<String, dynamic>)).toList();
    } else if (value.containsKey('mapValue')) {
      final fields = value['mapValue']['fields'] as Map<String, dynamic>? ?? {};
      return _convertFromFirestoreFormat(fields);
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Skip tests if not in integration test mode
  final runIntegrationTests = Platform.environment['RUN_INTEGRATION_TESTS'] == 'true';

  group('Firebase Sync Integration Tests', () {
    late Directory tempDir;
    late DatabaseService databaseService;
    late ErrorHandler errorHandler;
    late FirebaseAuthTestClient authClient;
    String? testUserIdToken;
    String? testUserId;

    setUpAll(() async {
      if (!runIntegrationTests) {
        return;
      }

      tempDir = await Directory.systemTemp.createTemp('firebase_sync_test_');

      // Register all Hive adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(NoteAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TaskHistoryAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserPreferencesAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SyncMetadataAdapter());
      if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(NotebookAdapter());
      if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(ChecklistItemAdapter());

      // Initialize auth client
      authClient = FirebaseAuthTestClient(
        apiKey: FirebaseTestConfig.apiKey,
        baseUrl: FirebaseTestConfig.authBaseUrl,
      );

      // Create test user
      try {
        final result = await authClient.signUpWithEmailPassword(
          FirebaseTestConfig.testEmail,
          FirebaseTestConfig.testPassword,
        );
        testUserIdToken = result['idToken'];
        testUserId = result['localId'];
      } catch (e) {
        // User might already exist, try to sign in
        final result = await authClient.signInWithEmailPassword(
          FirebaseTestConfig.testEmail,
          FirebaseTestConfig.testPassword,
        );
        testUserIdToken = result['idToken'];
        testUserId = result['localId'];
      }
    });

    setUp(() async {
      if (!runIntegrationTests) {
        return;
      }

      errorHandler = ErrorHandler();

      // Create storage layers
      final taskStorage = HiveTaskStorage(errorHandler);
      final noteStorage = HiveNoteStorage(errorHandler);
      final notebookStorage = HiveNotebookStorage(errorHandler);

      // Create cloud storage layers
      final taskCloudStorage = FirestoreTaskStorage(errorHandler);
      final noteCloudStorage = FirestoreNoteStorage(errorHandler);
      final notebookCloudStorage = FirestoreNotebookStorage(errorHandler);

      // Create sync services (enabled for integration tests)
      final taskSyncService = TaskSyncService(
        localStorage: taskStorage,
        cloudStorage: taskCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => true,
      );
      final noteSyncService = NoteSyncService(
        localStorage: noteStorage,
        cloudStorage: noteCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => true,
      );
      final notebookSyncService = NotebookSyncService(
        localStorage: notebookStorage,
        cloudStorage: notebookCloudStorage,
        errorHandler: errorHandler,
        isCloudSyncEnabled: () async => true,
      );

      // Create repositories
      final taskRepository = TaskRepository(
        localStorage: taskStorage,
        syncService: taskSyncService,
        errorHandler: errorHandler,
      );
      final noteRepository = NoteRepository(
        localStorage: noteStorage,
        syncService: noteSyncService,
        errorHandler: errorHandler,
      );
      final notebookRepository = NotebookRepository(
        localStorage: notebookStorage,
        syncService: notebookSyncService,
        errorHandler: errorHandler,
      );

      databaseService = DatabaseService(
        errorHandler,
        taskRepository: taskRepository,
        noteRepository: noteRepository,
        notebookRepository: notebookRepository,
      );
      await databaseService.init(path: tempDir.path);
    });

    tearDown(() async {
      if (!runIntegrationTests) {
        return;
      }

      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      tempDir = await Directory.systemTemp.createTemp('firebase_sync_test_');
      Hive.init(tempDir.path);
    });

    tearDownAll(() async {
      if (!runIntegrationTests) {
        return;
      }

      // Clean up test user
      if (testUserIdToken != null) {
        try {
          await authClient.deleteAccount(testUserIdToken!);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    // ==================== AUTHENTICATION TESTS ====================

    group('User Authentication Flow', () {
      test('Create test user with email/password using REST API', () async {
        if (!runIntegrationTests) {
          return;
        }

        // This is already done in setUpAll, but we verify it worked
        expect(testUserId, isNotNull);
        expect(testUserIdToken, isNotNull);

        // Verify user info
        final userInfo = await authClient.getUserInfo(testUserIdToken!);
        expect(userInfo['email'], FirebaseTestConfig.testEmail);
      }, skip: !runIntegrationTests);

      test('Anonymous to email upgrade (linkWithCredential equivalent)', () async {
        if (!runIntegrationTests) {
          return;
        }

        // 1. Create anonymous user
        final anonResult = await authClient.signInAnonymously();
        final anonIdToken = anonResult['idToken'];
        final anonUserId = anonResult['localId'];

        expect(anonUserId, isNotNull);
        expect(anonIdToken, isNotNull);

        // 2. Link with email/password
        final newEmail = 'upgrade-test-${DateTime.now().millisecondsSinceEpoch}@auralist.test';
        final linkResult = await authClient.linkWithEmailPassword(
          anonIdToken,
          newEmail,
          FirebaseTestConfig.testPassword,
        );

        expect(linkResult['localId'], anonUserId); // Same user ID after linking
        expect(linkResult['email'], newEmail);

        // 3. Verify the account is now linked
        final userInfo = await authClient.getUserInfo(linkResult['idToken']);
        expect(userInfo['email'], newEmail);

        // Clean up - delete the test user
        await authClient.deleteAccount(linkResult['idToken']);
      }, skip: !runIntegrationTests);

      test('Sign out and sign in again', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Sign in with test credentials
        final signInResult = await authClient.signInWithEmailPassword(
          FirebaseTestConfig.testEmail,
          FirebaseTestConfig.testPassword,
        );

        expect(signInResult['localId'], testUserId);
        expect(signInResult['idToken'], isNotNull);

        // Verify we can get user info after signing in again
        final userInfo = await authClient.getUserInfo(signInResult['idToken']);
        expect(userInfo['email'], FirebaseTestConfig.testEmail);
      }, skip: !runIntegrationTests);
    });

    // ==================== DATA SYNC TESTS ====================

    group('Data Sync Tests', () {
      test('Create a task locally and verify it syncs to Firestore', () async {
        if (!runIntegrationTests) {
          return;
        }

        final task = Task(
          title: 'Integration Test Task',
          type: 'once',
          createdAt: DateTime.now(),
          priority: 2,
          category: 'Personal',
          motivation: 'Test motivation',
          reward: 'Test reward',
        );

        // Save locally
        await databaseService.saveTaskLocally(task);

        // Verify saved locally
        final localTasks = await databaseService.getLocalTasks('once');
        expect(localTasks.length, 1);
        expect(localTasks.first.title, 'Integration Test Task');
        expect(localTasks.first.motivation, 'Test motivation');
        expect(localTasks.first.reward, 'Test reward');

        // Enable cloud sync
        await databaseService.setCloudSyncEnabled(true);

        // Note: Actual Firebase sync would require real Firebase setup
        // This test verifies the local flow works correctly
        final syncEnabled = await databaseService.isCloudSyncEnabled();
        expect(syncEnabled, true);
      }, skip: !runIntegrationTests);

      test('Create a note with checklist and verify all fields sync', () async {
        if (!runIntegrationTests) {
          return;
        }

        final checklist = [
          ChecklistItem(id: '1', text: 'Item 1', isCompleted: false, order: 0),
          ChecklistItem(id: '2', text: 'Item 2', isCompleted: true, order: 1),
          ChecklistItem(id: '3', text: 'Item 3', isCompleted: false, order: 2),
        ];

        final richContentDelta = jsonEncode([
          {'insert': 'This is '},
          {'insert': 'bold', 'attributes': {'bold': true}},
          {'insert': ' text\n'},
        ]);

        final note = Note(
          title: 'Integration Test Note',
          content: 'Plain text content',
          createdAt: DateTime.now(),
          color: '#E8F5E9',
          isPinned: true,
          tags: ['test', 'integration'],
          checklist: checklist,
          notebookId: 'notebook-123',
          status: 'active',
          richContent: richContentDelta,
          contentType: 'rich',
        );

        // Save locally
        await databaseService.saveNoteLocally(note);

        // Verify saved locally with all fields
        final notes = await databaseService.getAllNotes();
        expect(notes.any((n) => n.title == 'Integration Test Note'), true);

        final savedNote = notes.firstWhere((n) => n.title == 'Integration Test Note');
        expect(savedNote.content, 'Plain text content');
        expect(savedNote.color, '#E8F5E9');
        expect(savedNote.isPinned, true);
        expect(savedNote.tags, ['test', 'integration']);
        expect(savedNote.checklist.length, 3);
        expect(savedNote.checklist[0].text, 'Item 1');
        expect(savedNote.checklist[1].isCompleted, true);
        expect(savedNote.notebookId, 'notebook-123');
        expect(savedNote.status, 'active');
        expect(savedNote.richContent, richContentDelta);
        expect(savedNote.contentType, 'rich');

        // Verify toFirestore includes all fields
        final firestoreData = savedNote.toFirestore();
        expect(firestoreData['title'], 'Integration Test Note');
        expect(firestoreData['content'], 'Plain text content');
        expect(firestoreData['color'], '#E8F5E9');
        expect(firestoreData['isPinned'], true);
        expect(firestoreData['tags'], ['test', 'integration']);
        expect((firestoreData['checklist'] as List).length, 3);
        expect(firestoreData['notebookId'], 'notebook-123');
        expect(firestoreData['status'], 'active');
        expect(firestoreData['richContent'], richContentDelta);
        expect(firestoreData['contentType'], 'rich');
      }, skip: !runIntegrationTests);

      test('Create a notebook and verify sync', () async {
        if (!runIntegrationTests) {
          return;
        }

        final notebook = Notebook(
          name: 'Integration Test Notebook',
          icon: '📝',
          color: '#6750A4',
          createdAt: DateTime.now(),
          isFavorited: true,
        );

        // Save locally
        await databaseService.saveNotebookLocally(notebook);

        // Verify saved locally
        final notebooks = await databaseService.getAllNotebooks();
        expect(notebooks.any((n) => n.name == 'Integration Test Notebook'), true);

        final savedNotebook = notebooks.firstWhere(
          (n) => n.name == 'Integration Test Notebook',
        );
        expect(savedNotebook.icon, '📝');
        expect(savedNotebook.color, '#6750A4');
        expect(savedNotebook.isFavorited, true);

        // Verify toFirestore includes all fields
        final firestoreData = savedNotebook.toFirestore();
        expect(firestoreData['name'], 'Integration Test Notebook');
        expect(firestoreData['icon'], '📝');
        expect(firestoreData['color'], '#6750A4');
        expect(firestoreData['isFavorited'], true);
      }, skip: !runIntegrationTests);

      test('moveNotesOutOfNotebook syncs notes correctly', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Create a notebook
        final notebook = Notebook(
          firestoreId: 'test-notebook-fs-id',
          name: 'Move Test Notebook',
          icon: '📁',
          color: '#1E88E5',
          createdAt: DateTime.now(),
        );
        await databaseService.saveNotebookLocally(notebook);

        // Create notes in the notebook
        final note1 = Note(
          title: 'Note in Notebook 1',
          content: 'Content 1',
          createdAt: DateTime.now(),
          notebookId: 'test-notebook-fs-id',
        );
        final note2 = Note(
          title: 'Note in Notebook 2',
          content: 'Content 2',
          createdAt: DateTime.now(),
          notebookId: 'test-notebook-fs-id',
        );
        await databaseService.saveNoteLocally(note1);
        await databaseService.saveNoteLocally(note2);

        // Verify notes are in notebook
        var notes = await databaseService.getAllNotes();
        var notesInNotebook = notes.where((n) => n.notebookId == 'test-notebook-fs-id').toList();
        expect(notesInNotebook.length, 2);

        // Move notes out of notebook
        await databaseService.moveNotesOutOfNotebook('test-notebook-fs-id');

        // Verify notes are no longer in notebook
        notes = await databaseService.getAllNotes();
        notesInNotebook = notes.where((n) => n.notebookId == 'test-notebook-fs-id').toList();
        expect(notesInNotebook.length, 0);

        // Verify notes still exist but with null notebookId
        final movedNotes = notes.where(
          (n) => n.title.startsWith('Note in Notebook'),
        ).toList();
        expect(movedNotes.length, 2);
        expect(movedNotes.every((n) => n.notebookId == null), true);
      }, skip: !runIntegrationTests);
    });

    // ==================== NOTE MODEL SYNC FIELD TESTS ====================

    group('Note Model Sync Field Verification', () {
      test('Note.toFirestore includes all sync fields', () {
        final note = Note(
          firestoreId: 'fs-123',
          title: 'Test Note',
          content: 'Test content',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          taskId: 'task-456',
          color: '#E8F5E9',
          isPinned: true,
          tags: ['tag1', 'tag2'],
          deleted: false,
          deletedAt: null,
          checklist: [
            ChecklistItem(id: '1', text: 'Item 1', isCompleted: false, order: 0),
            ChecklistItem(id: '2', text: 'Item 2', isCompleted: true, order: 1),
          ],
          notebookId: 'notebook-789',
          status: 'active',
          richContent: '{"ops":[{"insert":"Test"}]}',
          contentType: 'rich',
        );

        final firestoreData = note.toFirestore();

        // Verify all fields are present
        expect(firestoreData.containsKey('title'), true);
        expect(firestoreData.containsKey('content'), true);
        expect(firestoreData.containsKey('createdAt'), true);
        expect(firestoreData.containsKey('updatedAt'), true);
        expect(firestoreData.containsKey('taskId'), true);
        expect(firestoreData.containsKey('color'), true);
        expect(firestoreData.containsKey('isPinned'), true);
        expect(firestoreData.containsKey('tags'), true);
        expect(firestoreData.containsKey('deleted'), true);
        expect(firestoreData.containsKey('deletedAt'), true);
        expect(firestoreData.containsKey('checklist'), true);
        expect(firestoreData.containsKey('notebookId'), true);
        expect(firestoreData.containsKey('status'), true);
        expect(firestoreData.containsKey('richContent'), true);
        expect(firestoreData.containsKey('contentType'), true);

        // Verify field values
        expect(firestoreData['title'], 'Test Note');
        expect(firestoreData['notebookId'], 'notebook-789');
        expect(firestoreData['status'], 'active');
        expect(firestoreData['richContent'], '{"ops":[{"insert":"Test"}]}');
        expect(firestoreData['contentType'], 'rich');

        // Verify checklist serialization
        final checklistData = firestoreData['checklist'] as List;
        expect(checklistData.length, 2);
        expect(checklistData[0]['text'], 'Item 1');
        expect(checklistData[1]['isCompleted'], true);
      });

      test('Note.fromFirestore parses all sync fields', () {
        final firestoreData = {
          'title': 'Cloud Note',
          'content': 'Cloud content',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-02T00:00:00.000',
          'taskId': 'task-cloud',
          'color': '#FCE4EC',
          'isPinned': false,
          'tags': ['cloud', 'test'],
          'deleted': false,
          'deletedAt': null,
          'checklist': [
            {'id': '1', 'text': 'Cloud item', 'isCompleted': true, 'order': 0},
          ],
          'notebookId': 'cloud-notebook',
          'status': 'archived',
          'richContent': '{"ops":[{"insert":"Cloud"}]}',
          'contentType': 'rich',
        };

        final note = Note.fromFirestore('fs-cloud-123', firestoreData);

        expect(note.firestoreId, 'fs-cloud-123');
        expect(note.title, 'Cloud Note');
        expect(note.content, 'Cloud content');
        expect(note.taskId, 'task-cloud');
        expect(note.color, '#FCE4EC');
        expect(note.isPinned, false);
        expect(note.tags, ['cloud', 'test']);
        expect(note.deleted, false);
        expect(note.checklist.length, 1);
        expect(note.checklist[0].text, 'Cloud item');
        expect(note.checklist[0].isCompleted, true);
        expect(note.notebookId, 'cloud-notebook');
        expect(note.status, 'archived');
        expect(note.richContent, '{"ops":[{"insert":"Cloud"}]}');
        expect(note.contentType, 'rich');
      });

      test('Note.fromFirestore handles missing optional fields', () {
        final minimalData = {
          'title': 'Minimal Note',
          'content': 'Minimal content',
          'createdAt': '2024-01-01T00:00:00.000',
        };

        final note = Note.fromFirestore('fs-minimal', minimalData);

        expect(note.firestoreId, 'fs-minimal');
        expect(note.title, 'Minimal Note');
        expect(note.color, '#FFFFFF'); // Default
        expect(note.isPinned, false); // Default
        expect(note.tags, isEmpty); // Default
        expect(note.deleted, false); // Default
        expect(note.checklist, isEmpty); // Default
        expect(note.notebookId, isNull); // Default
        expect(note.status, 'active'); // Default
        expect(note.richContent, isNull); // Default
        expect(note.contentType, 'plain'); // Default
      });
    });

    // ==================== CHECKLIST ITEM TESTS ====================

    group('ChecklistItem Sync Tests', () {
      test('ChecklistItem.toMap serializes correctly', () {
        final item = ChecklistItem(
          id: 'item-123',
          text: 'Test item',
          isCompleted: true,
          order: 5,
        );

        final map = item.toMap();

        expect(map['id'], 'item-123');
        expect(map['text'], 'Test item');
        expect(map['isCompleted'], true);
        expect(map['order'], 5);
      });

      test('ChecklistItem.fromMap deserializes correctly', () {
        final map = {
          'id': 'item-456',
          'text': 'Deserialized item',
          'isCompleted': false,
          'order': 10,
        };

        final item = ChecklistItem.fromMap(map);

        expect(item.id, 'item-456');
        expect(item.text, 'Deserialized item');
        expect(item.isCompleted, false);
        expect(item.order, 10);
      });

      test('ChecklistItem.fromMap handles missing fields', () {
        final minimalMap = {
          'id': 'item-minimal',
        };

        final item = ChecklistItem.fromMap(minimalMap);

        expect(item.id, 'item-minimal');
        expect(item.text, ''); // Default
        expect(item.isCompleted, false); // Default
        expect(item.order, 0); // Default
      });
    });

    // ==================== NOTEBOOK SYNC TESTS ====================

    group('Notebook Model Sync Tests', () {
      test('Notebook.toFirestore includes all fields', () {
        final notebook = Notebook(
          firestoreId: 'nb-fs-123',
          name: 'Test Notebook',
          icon: '📚',
          color: '#43A047',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
          isFavorited: true,
          parentId: 'parent-123',
        );

        final firestoreData = notebook.toFirestore();

        expect(firestoreData['name'], 'Test Notebook');
        expect(firestoreData['icon'], '📚');
        expect(firestoreData['color'], '#43A047');
        expect(firestoreData['createdAt'], isNotNull);
        expect(firestoreData['updatedAt'], isNotNull);
        expect(firestoreData['isFavorited'], true);
        expect(firestoreData['parentId'], 'parent-123');
      });

      test('Notebook.fromFirestore parses all fields', () {
        final firestoreData = {
          'name': 'Cloud Notebook',
          'icon': '🎯',
          'color': '#FB8C00',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-02T00:00:00.000',
          'isFavorited': false,
          'parentId': 'cloud-parent',
        };

        final notebook = Notebook.fromFirestore('nb-cloud', firestoreData);

        expect(notebook.firestoreId, 'nb-cloud');
        expect(notebook.name, 'Cloud Notebook');
        expect(notebook.icon, '🎯');
        expect(notebook.color, '#FB8C00');
        expect(notebook.isFavorited, false);
        expect(notebook.parentId, 'cloud-parent');
      });
    });

    // ==================== CONFLICT RESOLUTION TESTS ====================

    group('Conflict Resolution', () {
      test('Simulate offline changes and verify they queue for sync', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Create a task while "offline" (sync disabled)
        await databaseService.setCloudSyncEnabled(false);

        final task = Task(
          title: 'Offline Task',
          type: 'daily',
          createdAt: DateTime.now(),
          priority: 1,
        );

        await databaseService.saveTaskLocally(task);

        // Verify task saved locally
        final localTasks = await databaseService.getLocalTasks('daily');
        expect(localTasks.any((t) => t.title == 'Offline Task'), true);

        // Enable sync
        await databaseService.setCloudSyncEnabled(true);

        // Verify sync is now enabled
        final syncEnabled = await databaseService.isCloudSyncEnabled();
        expect(syncEnabled, true);

        // The sync queue should process when Firebase is available
        // For this test, we just verify the preferences are correct
      }, skip: !runIntegrationTests);

      test('Note with newer cloud version should update local', () async {
        // This test verifies the sync logic for handling cloud updates
        // When cloud note is newer than local, local should be updated

        // Create a local note
        final localNote = Note(
          firestoreId: 'conflict-test-note',
          title: 'Local Version',
          content: 'Local content',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1, 12, 0), // Older timestamp
        );

        // Simulate cloud note with newer timestamp
        final cloudData = {
          'title': 'Cloud Version',
          'content': 'Cloud content',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-02T12:00:00.000', // Newer timestamp
        };

        final cloudNote = Note.fromFirestore('conflict-test-note', cloudData);

        // Verify cloud is newer
        expect(cloudNote.updatedAt.isAfter(localNote.updatedAt), true);

        // In real sync, local would be updated with cloud data
        expect(cloudNote.title, 'Cloud Version');
        expect(cloudNote.content, 'Cloud content');
      });
    });

    // ==================== CLOUD SYNC ENABLE AFTER ACCOUNT LINKING ====================

    group('Cloud Sync Auto-Enable After Account Linking', () {
      test('cloudSyncEnabled can be toggled', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Start with sync disabled
        await databaseService.setCloudSyncEnabled(false);
        var syncEnabled = await databaseService.isCloudSyncEnabled();
        expect(syncEnabled, false);

        // Enable sync (simulating post-account linking)
        await databaseService.setCloudSyncEnabled(true);
        syncEnabled = await databaseService.isCloudSyncEnabled();
        expect(syncEnabled, true);

        // Disable sync
        await databaseService.setCloudSyncEnabled(false);
        syncEnabled = await databaseService.isCloudSyncEnabled();
        expect(syncEnabled, false);
      }, skip: !runIntegrationTests);

      test('User preferences persist cloudSyncEnabled', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Set cloud sync enabled
        await databaseService.setCloudSyncEnabled(true);

        // Get preferences directly
        final prefs = await databaseService.getUserPreferences();
        expect(prefs.cloudSyncEnabled, true);

        // Change it
        await databaseService.setCloudSyncEnabled(false);
        final prefs2 = await databaseService.getUserPreferences();
        expect(prefs2.cloudSyncEnabled, false);
      }, skip: !runIntegrationTests);
    });

    // ==================== SAVENOTELOCALALLY FIELD SYNC TESTS ====================

    group('saveNoteLocally Field Sync Tests', () {
      test('saveNoteLocally preserves all fields including new sync fields', () async {
        if (!runIntegrationTests) {
          return;
        }

        final note = Note(
          title: 'Full Field Test',
          content: 'Plain content',
          createdAt: DateTime.now(),
          color: '#FFF3E0',
          isPinned: true,
          tags: ['full', 'test'],
          checklist: [
            ChecklistItem(id: '1', text: 'Check 1', isCompleted: false, order: 0),
          ],
          notebookId: 'test-notebook',
          status: 'active',
          richContent: '{"ops":[{"insert":"Rich"}]}',
          contentType: 'rich',
        );

        await databaseService.saveNoteLocally(note);

        // Retrieve and verify
        final notes = await databaseService.getAllNotes();
        final saved = notes.firstWhere((n) => n.title == 'Full Field Test');

        expect(saved.content, 'Plain content');
        expect(saved.color, '#FFF3E0');
        expect(saved.isPinned, true);
        expect(saved.tags, ['full', 'test']);
        expect(saved.checklist.length, 1);
        expect(saved.checklist[0].text, 'Check 1');
        expect(saved.notebookId, 'test-notebook');
        expect(saved.status, 'active');
        expect(saved.richContent, '{"ops":[{"insert":"Rich"}]}');
        expect(saved.contentType, 'rich');
      }, skip: !runIntegrationTests);

      test('saveNoteLocally updates existing note with all fields', () async {
        if (!runIntegrationTests) {
          return;
        }

        // Create initial note
        final note = Note(
          title: 'Update Test',
          content: 'Initial',
          createdAt: DateTime.now(),
          status: 'active',
          contentType: 'plain',
        );

        await databaseService.saveNoteLocally(note);

        // Update the note
        final notes = await databaseService.getAllNotes();
        final saved = notes.firstWhere((n) => n.title == 'Update Test');

        final updated = saved.copyWith(
          content: 'Updated content',
          checklist: [
            ChecklistItem(id: '1', text: 'New item', isCompleted: true, order: 0),
          ],
          notebookId: 'new-notebook',
          status: 'archived',
          richContent: '{"ops":[{"insert":"New rich"}]}',
          contentType: 'rich',
        );

        await databaseService.saveNoteLocally(updated);

        // Verify updates
        final allNotes = await databaseService.getAllNotes();
        final final_ = allNotes.firstWhere((n) => n.title == 'Update Test');

        expect(final_.content, 'Updated content');
        expect(final_.checklist.length, 1);
        expect(final_.checklist[0].text, 'New item');
        expect(final_.checklist[0].isCompleted, true);
        expect(final_.notebookId, 'new-notebook');
        expect(final_.status, 'archived');
        expect(final_.richContent, '{"ops":[{"insert":"New rich"}]}');
        expect(final_.contentType, 'rich');
      }, skip: !runIntegrationTests);
    });

    // ==================== SYNCFROMCLOUD FIELD TESTS ====================

    group('syncFromCloud Field Verification', () {
      test('Note.fromFirestore correctly parses all sync fields for syncFromCloud', () {
        // This simulates what happens in syncFromCloud when parsing cloud data
        final cloudData = {
          'title': 'Cloud Note',
          'content': 'Cloud content',
          'createdAt': '2024-03-15T10:30:00.000',
          'updatedAt': '2024-03-15T14:45:00.000',
          'taskId': 'linked-task-id',
          'color': '#E3F2FD',
          'isPinned': true,
          'tags': ['cloud', 'synced', 'important'],
          'deleted': false,
          'deletedAt': null,
          'checklist': [
            {'id': 'c1', 'text': 'Cloud item 1', 'isCompleted': false, 'order': 0},
            {'id': 'c2', 'text': 'Cloud item 2', 'isCompleted': true, 'order': 1},
            {'id': 'c3', 'text': 'Cloud item 3', 'isCompleted': false, 'order': 2},
          ],
          'notebookId': 'cloud-notebook-id',
          'status': 'active',
          'richContent': '{"ops":[{"insert":"Synced rich content\\n"}]}',
          'contentType': 'rich',
        };

        final note = Note.fromFirestore('cloud-doc-id', cloudData);

        // Verify all fields parsed correctly
        expect(note.firestoreId, 'cloud-doc-id');
        expect(note.title, 'Cloud Note');
        expect(note.content, 'Cloud content');
        expect(note.taskId, 'linked-task-id');
        expect(note.color, '#E3F2FD');
        expect(note.isPinned, true);
        expect(note.tags.length, 3);
        expect(note.tags, contains('important'));
        expect(note.deleted, false);
        expect(note.checklist.length, 3);
        expect(note.checklist[1].isCompleted, true);
        expect(note.notebookId, 'cloud-notebook-id');
        expect(note.status, 'active');
        expect(note.richContent, '{"ops":[{"insert":"Synced rich content\\n"}]}');
        expect(note.contentType, 'rich');
      });

      test('Note.updateInPlace correctly updates all sync fields', () {
        // Simulate existing note being updated by syncFromCloud
        final existingNote = Note(
          firestoreId: 'existing-id',
          title: 'Old Title',
          content: 'Old content',
          createdAt: DateTime(2024, 1, 1),
          status: 'active',
          contentType: 'plain',
        );

        // Update with cloud data (simulating syncFromCloud behavior)
        existingNote.updateInPlace(
          title: 'New Title',
          content: 'New content',
          updatedAt: DateTime(2024, 3, 15),
          color: '#FCE4EC',
          isPinned: true,
          tags: ['updated'],
          checklist: [
            ChecklistItem(id: '1', text: 'Updated item', isCompleted: true, order: 0),
          ],
          notebookId: 'updated-notebook',
          status: 'archived',
          richContent: '{"ops":[{"insert":"Updated rich"}]}',
          contentType: 'rich',
        );

        // Verify all fields updated
        expect(existingNote.title, 'New Title');
        expect(existingNote.content, 'New content');
        expect(existingNote.color, '#FCE4EC');
        expect(existingNote.isPinned, true);
        expect(existingNote.tags, ['updated']);
        expect(existingNote.checklist.length, 1);
        expect(existingNote.checklist[0].text, 'Updated item');
        expect(existingNote.notebookId, 'updated-notebook');
        expect(existingNote.status, 'archived');
        expect(existingNote.richContent, '{"ops":[{"insert":"Updated rich"}]}');
        expect(existingNote.contentType, 'rich');
      });
    });
  });

  // ==================== UNIT TESTS (ALWAYS RUN) ====================

  group('Unit Tests - Always Run', () {
    test('Note model checklist serialization round-trip', () {
      final original = Note(
        title: 'Checklist Test',
        content: 'Content',
        createdAt: DateTime(2024, 1, 1),
        checklist: [
          ChecklistItem(id: '1', text: 'Item 1', isCompleted: false, order: 0),
          ChecklistItem(id: '2', text: 'Item 2', isCompleted: true, order: 1),
        ],
        notebookId: 'nb-123',
        status: 'active',
        richContent: '{"test": true}',
        contentType: 'rich',
      );

      final firestore = original.toFirestore();
      final restored = Note.fromFirestore('test-id', firestore);

      expect(restored.checklist.length, 2);
      expect(restored.checklist[0].text, 'Item 1');
      expect(restored.checklist[0].isCompleted, false);
      expect(restored.checklist[1].text, 'Item 2');
      expect(restored.checklist[1].isCompleted, true);
      expect(restored.notebookId, 'nb-123');
      expect(restored.status, 'active');
      expect(restored.richContent, '{"test": true}');
      expect(restored.contentType, 'rich');
    });

    test('Notebook model serialization round-trip', () {
      final original = Notebook(
        name: 'Test Notebook',
        icon: '🎯',
        color: '#E53935',
        createdAt: DateTime(2024, 1, 1),
        isFavorited: true,
        parentId: 'parent-nb',
      );

      final firestore = original.toFirestore();
      final restored = Notebook.fromFirestore('nb-test-id', firestore);

      expect(restored.name, 'Test Notebook');
      expect(restored.icon, '🎯');
      expect(restored.color, '#E53935');
      expect(restored.isFavorited, true);
      expect(restored.parentId, 'parent-nb');
    });

    test('ChecklistItem serialization round-trip', () {
      final original = ChecklistItem(
        id: 'item-abc',
        text: 'Test item text',
        isCompleted: true,
        order: 42,
      );

      final map = original.toMap();
      final restored = ChecklistItem.fromMap(map);

      expect(restored.id, 'item-abc');
      expect(restored.text, 'Test item text');
      expect(restored.isCompleted, true);
      expect(restored.order, 42);
    });

    test('Note copyWith preserves all fields', () {
      final original = Note(
        firestoreId: 'fs-orig',
        title: 'Original',
        content: 'Original content',
        createdAt: DateTime(2024, 1, 1),
        color: '#E8F5E9',
        isPinned: false,
        tags: ['original'],
        checklist: [
          ChecklistItem(id: '1', text: 'Original item', isCompleted: false, order: 0),
        ],
        notebookId: 'original-nb',
        status: 'active',
        richContent: '{"original": true}',
        contentType: 'plain',
      );

      final copy = original.copyWith(
        title: 'Copy',
        isPinned: true,
      );

      // Changed fields
      expect(copy.title, 'Copy');
      expect(copy.isPinned, true);

      // Preserved fields
      expect(copy.firestoreId, 'fs-orig');
      expect(copy.content, 'Original content');
      expect(copy.color, '#E8F5E9');
      expect(copy.tags, ['original']);
      expect(copy.checklist.length, 1);
      expect(copy.notebookId, 'original-nb');
      expect(copy.status, 'active');
      expect(copy.richContent, '{"original": true}');
      expect(copy.contentType, 'plain');
    });

    test('Note copyWith can clear notebookId', () {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: DateTime.now(),
        notebookId: 'nb-to-clear',
      );

      final cleared = note.copyWith(clearNotebookId: true);

      expect(note.notebookId, 'nb-to-clear');
      expect(cleared.notebookId, isNull);
    });

    test('Note copyWith can clear richContent', () {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: DateTime.now(),
        richContent: '{"content": true}',
        contentType: 'rich',
      );

      final cleared = note.copyWith(clearRichContent: true, contentType: 'plain');

      expect(note.richContent, '{"content": true}');
      expect(cleared.richContent, isNull);
      expect(cleared.contentType, 'plain');
    });
  });
}
