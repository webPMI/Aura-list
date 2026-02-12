import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/providers/task_provider.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/services/auth_service.dart';
import 'package:checklist_app/services/error_handler.dart';
import 'package:checklist_app/models/task_model.dart';
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

// Manual Mock for DatabaseService
class MockDatabaseService implements DatabaseService {
  final List<Task> _tasks = [];
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Stream<List<Task>> watchLocalTasks(String type) => _controller.stream;

  @override
  Future<void> saveTaskLocally(Task task) async {
    final index = _tasks.indexWhere((t) => t.createdAt == task.createdAt);
    if (index != -1) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
    _controller.add(List.from(_tasks));
  }

  @override
  Future<void> deleteTaskLocally(dynamic key) async {
    _tasks.removeWhere((t) => t.key == key);
    _controller.add(List.from(_tasks));
  }

  @override
  Future<void> init({String? path}) async {}

  @override
  Future<void> syncTaskToCloud(Task task, String userId) async {}

  @override
  Future<void> syncTaskToCloudDebounced(Task task, String userId) async {}

  @override
  Future<void> deleteTaskFromCloud(String firestoreId, String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TaskProvider Tests', () {
    late ProviderContainer container;
    late MockAuthService mockAuth;
    late MockDatabaseService mockDb;

    setUp(() {
      mockAuth = MockAuthService();
      mockDb = MockDatabaseService();
      final errorHandler = ErrorHandler();

      container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuth),
          databaseServiceProvider.overrideWithValue(mockDb),
          errorHandlerProvider.overrideWithValue(errorHandler),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is empty', () async {
      container.listen(tasksProvider('daily'), (_, __) {});
      final tasks = container.read(tasksProvider('daily'));
      expect(tasks, isEmpty);
    });

    test('addTask updates state via stream', () async {
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);

      // Trigger addTask
      await notifier.addTask('Test Task');

      // Check state
      final tasks = container.read(tasksProvider('daily'));
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Task');
    });

    test('toggleTask changes completion status', () async {
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);
      await notifier.addTask('Toggle Me');

      final task = container.read(tasksProvider('daily')).first;
      expect(task.isCompleted, false);

      await notifier.toggleTask(task);

      expect(container.read(tasksProvider('daily')).first.isCompleted, true);
    });

    test('deleteTask removes task from state', () async {
      container.listen(tasksProvider('daily'), (_, __) {});

      final notifier = container.read(tasksProvider('daily').notifier);
      await notifier.addTask('Delete Me');

      final task = container.read(tasksProvider('daily')).first;
      // In the mock, we need to ensure key is set for deletion to work if deleteTask uses it.
      // For simplicity in this mock, we'll just check if it removes it.
      await notifier.deleteTask(task);

      expect(container.read(tasksProvider('daily')), isEmpty);
    });
  });
}
