import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:checklist_app/providers/task_provider.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';
import 'package:checklist_app/models/task_history.dart';
import 'package:checklist_app/models/sync_metadata.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/models/notebook_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checklist_app/services/session_cache_manager.dart';

// Manual Mock for AuthService
class MockAuthService implements AuthService {
  @override
  User? currentUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(currentUser);

  @override
  bool get isFirebaseAvailable => false;

  @override
  bool get isLinkedAccount => currentUser != null;

  @override
  String? get linkedEmail => null;

  @override
  String? get linkedProvider => null;

  @override
  Future<void> signOut({
    bool clearCache = false,
    bool preservePreferences = true,
  }) async {}

  @override
  Future<void> signOutAndClear() async {}

  @override
  void refreshFirebaseAvailability() {}

  @override
  Future<UserCredential?> signInAnonymously() async => null;

  @override
  Future<UserCredential?> linkWithEmailPassword(
    String email,
    String password,
  ) async => null;

  @override
  Future<({UserCredential? credential, String? error})>
  linkWithGoogle() async => (credential: null, error: null);

  @override
  Future<bool> deleteAccount(DatabaseService dbService) async => true;

  @override
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async => null;

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<bool> sendPasswordResetEmail(String email) async => true;

  @override
  Future<void> prepareSession(String userId) async {}

  @override
  Future<bool> validateCacheForUser(String userId) async => true;

  @override
  Future<void> clearCacheIfDifferentUser(String newUserId) async {}

  @override
  Future<void> migrateAnonymousData(String oldUserId, String newUserId) async {}

  @override
  Future<DataExport> exportUserData() async => DataExport(
    data: {},
    exportedAt: DateTime.now(),
    taskCount: 0,
    noteCount: 0,
  );

  @override
  Future<Map<String, dynamic>> getCacheStats() async => {};

  @override
  Future<void> dispose() async {}

  @override
  bool get isDisposed => false;
}

void main() {
  group('TaskProvider Tests', () {
    late Directory tempDir;
    late ProviderContainer container;
    late MockAuthService mockAuth;
    late DatabaseService databaseService;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('task_provider_test_');
    });

    setUp(() async {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      tempDir = await Directory.systemTemp.createTemp('tpt_');

      mockAuth = MockAuthService();
      final errorHandler = ErrorHandler();
      databaseService = DatabaseService(errorHandler);
      await databaseService.init(path: tempDir.path);

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
          databaseServiceProvider.overrideWithValue(databaseService),
        ],
      );
    });

    tearDown(() async {
      // Container should be disposed after listening stops
      container.dispose();
      await Hive.close();
    });

    test('Initial state is empty', () async {
      container.listen(tasksProvider('daily'), (_, __) {});
      final tasks = container.read(tasksProvider('daily'));
      expect(tasks, isEmpty);
    });

    test('addTask updates state via stream', () async {
      // Listen to keep provider alive
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);
      await notifier.addTask('Test Task');

      // Wait for state update
      int attempts = 0;
      while (container.read(tasksProvider('daily')).isEmpty && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      final tasks = container.read(tasksProvider('daily'));
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Task');
    });

    test('toggleTask changes completion status', () async {
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);
      await notifier.addTask('Toggle Me');

      int attempts = 0;
      while (container.read(tasksProvider('daily')).isEmpty && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      final task = container.read(tasksProvider('daily')).first;
      expect(task.isCompleted, false);

      await notifier.toggleTask(task);

      attempts = 0;
      while (!container.read(tasksProvider('daily')).first.isCompleted &&
          attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      expect(container.read(tasksProvider('daily')).first.isCompleted, true);
    });

    test('deleteTask removes task from state', () async {
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);
      await notifier.addTask('Delete Me');

      int attempts = 0;
      while (container.read(tasksProvider('daily')).isEmpty && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      final task = container.read(tasksProvider('daily')).first;
      await notifier.deleteTask(task);

      attempts = 0;
      while (container.read(tasksProvider('daily')).isNotEmpty &&
          attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      expect(container.read(tasksProvider('daily')), isEmpty);
    });
  });
}
