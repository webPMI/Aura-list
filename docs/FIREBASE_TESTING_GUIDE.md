# Firebase Testing Guide for AuraList

This comprehensive guide covers testing Firebase integration in the AuraList app, including setup, test user management, sync operations verification, and troubleshooting common issues.

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Test User Management](#2-test-user-management)
3. [Running Tests](#3-running-tests)
4. [Testing Sync Operations](#4-testing-sync-operations)
5. [Common Issues and Solutions](#5-common-issues-and-solutions)
6. [Continuation Guide for Future Agents](#6-continuation-guide-for-future-agents)

---

## 1. Prerequisites

### Firebase Project Setup

1. **Firebase Console Access**
   - Project ID: `aura-list`
   - Console URL: https://console.firebase.google.com/project/aura-list

2. **Required Firebase Services**
   - Firebase Authentication (Anonymous + Google Sign-In enabled)
   - Cloud Firestore
   - Firebase Hosting (for web deployment)

3. **Configuration Files**
   ```
   android/app/google-services.json     # Android config
   ios/Runner/GoogleService-Info.plist  # iOS config
   lib/firebase_options.dart            # Dart config (auto-generated)
   ```

### Firebase Emulator Setup

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize Emulators** (if not already done)
   ```bash
   firebase init emulators
   ```
   Select: Authentication, Firestore, Hosting

3. **Start Emulators**
   ```bash
   firebase emulators:start
   ```

   Default ports:
   - Auth Emulator: http://localhost:9099
   - Firestore Emulator: http://localhost:8080
   - Hosting Emulator: http://localhost:5000
   - Emulator UI: http://localhost:4000

4. **Configure App to Use Emulators** (for testing)
   Add to your initialization code:
   ```dart
   import 'package:cloud_firestore/cloud_firestore.dart';
   import 'package:firebase_auth/firebase_auth.dart';

   // In development/test mode only
   if (kDebugMode) {
     FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
   }
   ```

### Required Environment Variables

For CI/CD or automated testing:
```bash
# Firebase service account (for admin operations)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Firebase project
FIREBASE_PROJECT_ID=aura-list

# Emulator host (for integration tests)
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
```

---

## 2. Test User Management

### Creating Test Users Programmatically

#### Anonymous Authentication (Primary Method)

The app uses anonymous authentication by default:

```dart
// In AuthService
Future<UserCredential?> signInAnonymously() async {
  if (!_firebaseAvailable || _auth == null) {
    return null; // Graceful degradation to local mode
  }
  return await _auth!.signInAnonymously();
}
```

#### Firebase Auth REST API for Testing

For programmatic test user creation:

**1. Create Anonymous User**
```bash
curl -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**2. Create Email/Password User**
```bash
curl -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "returnSecureToken": true
  }'
```

**3. Sign In Existing User**
```bash
curl -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123",
    "returnSecureToken": true
  }'
```

#### Using Firebase Admin SDK (for cleanup scripts)

```javascript
// cleanup-test-users.js
const admin = require('firebase-admin');
admin.initializeApp();

async function cleanupTestUsers() {
  const listUsersResult = await admin.auth().listUsers(1000);

  for (const user of listUsersResult.users) {
    // Delete users created more than 24 hours ago with no activity
    if (user.metadata.lastSignInTime === null) {
      await admin.auth().deleteUser(user.uid);
      console.log(`Deleted user: ${user.uid}`);
    }
  }
}

cleanupTestUsers();
```

### Cleanup Procedures

1. **Manual Cleanup via Firebase Console**
   - Go to Authentication > Users
   - Select test users and delete

2. **Automated Cleanup with Emulator**
   ```bash
   # Clear all emulator data
   firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data

   # Or clear Firestore only
   curl -X DELETE "http://localhost:8080/emulator/v1/projects/aura-list/databases/(default)/documents"
   ```

3. **Firestore Cleanup (production test data)**
   ```dart
   // Delete all test user data
   Future<void> deleteTestUserData(String userId) async {
     final batch = FirebaseFirestore.instance.batch();

     // Delete tasks
     final tasks = await FirebaseFirestore.instance
         .collection('users/$userId/tasks')
         .get();
     for (final doc in tasks.docs) {
       batch.delete(doc.reference);
     }

     // Delete notes
     final notes = await FirebaseFirestore.instance
         .collection('users/$userId/notes')
         .get();
     for (final doc in notes.docs) {
       batch.delete(doc.reference);
     }

     // Delete notebooks
     final notebooks = await FirebaseFirestore.instance
         .collection('users/$userId/notebooks')
         .get();
     for (final doc in notebooks.docs) {
       batch.delete(doc.reference);
     }

     await batch.commit();
   }
   ```

---

## 3. Running Tests

### Unit Tests for Services

**Location:** `test/services/`

**Run all unit tests:**
```bash
flutter test
```

**Run specific test files:**
```bash
# Database service tests
flutter test test/services/database_service_test.dart

# Auth service tests
flutter test test/auth_service_test.dart

# Error handler tests
flutter test test/services/error_handler_test.dart

# All model tests
flutter test test/models/
```

### Existing Test Coverage

| Test File | Description |
|-----------|-------------|
| `test/services/database_service_test.dart` | Local Hive operations (CRUD) |
| `test/auth_service_test.dart` | Auth service with Firebase unavailability |
| `test/database_test.dart` | Hive model adapters and serialization |
| `test/models/task_model_test.dart` | Task model unit tests |
| `test/models/note_model_test.dart` | Note model unit tests |
| `test/models/notebook_model_test.dart` | Notebook model unit tests |
| `test/services/conflict_resolver_test.dart` | Sync conflict resolution |
| `test/services/data_integrity_service_test.dart` | Data integrity checks |

### Integration Tests for Firebase Sync

Currently, integration tests are not implemented. To create them:

**1. Create integration test file:**
```dart
// integration_test/firebase_sync_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:checklist_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Sync Integration Tests', () {
    testWidgets('Task syncs to Firestore', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a task
      // Verify it appears in Firestore
      // Delete the task
      // Verify it's removed from Firestore
    });
  });
}
```

**2. Run integration tests:**
```bash
# With emulators
flutter test integration_test/firebase_sync_test.dart

# On a specific device
flutter test integration_test/ -d chrome
flutter test integration_test/ -d windows
```

### Testing with Emulators

```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Run tests
flutter test --dart-define=USE_FIREBASE_EMULATOR=true
```

---

## 4. Testing Sync Operations

### Firestore Document Structure

**User Document Path:** `users/{userId}`

**Tasks Collection:** `users/{userId}/tasks/{taskId}`
```json
{
  "title": "string (required, max 500 chars)",
  "type": "daily|weekly|monthly|yearly|once",
  "isCompleted": "boolean",
  "createdAt": "ISO 8601 string",
  "dueDate": "ISO 8601 string | null",
  "category": "Personal|Trabajo|Hogar|Salud|Otros",
  "priority": "0|1|2 (Low|Medium|High)",
  "dueTimeMinutes": "number | null (0-1439)",
  "motivation": "string | null",
  "reward": "string | null",
  "recurrenceDay": "number | null",
  "deadline": "ISO 8601 string | null",
  "deleted": "boolean",
  "deletedAt": "ISO 8601 string | null",
  "lastUpdatedAt": "ISO 8601 string | null"
}
```

**Notes Collection:** `users/{userId}/notes/{noteId}`
```json
{
  "title": "string (max 500 chars)",
  "content": "string (max 10000 chars)",
  "createdAt": "ISO 8601 string",
  "updatedAt": "ISO 8601 string",
  "taskId": "string | null",
  "color": "hex string (e.g., '#FFFFFF')",
  "isPinned": "boolean",
  "tags": "string[]",
  "deleted": "boolean",
  "deletedAt": "ISO 8601 string | null",
  "checklist": [
    {
      "id": "string",
      "text": "string",
      "isCompleted": "boolean",
      "order": "number"
    }
  ],
  "notebookId": "string | null",
  "status": "active|archived|deleted",
  "richContent": "string | null (Quill Delta JSON)",
  "contentType": "plain|checklist|rich"
}
```

**Notebooks Collection:** `users/{userId}/notebooks/{notebookId}`
```json
{
  "name": "string",
  "icon": "string (emoji)",
  "color": "hex string",
  "createdAt": "ISO 8601 string",
  "updatedAt": "ISO 8601 string",
  "isFavorited": "boolean",
  "parentId": "string | null"
}
```

### Verifying Data Synced Correctly

#### Using Firebase Console

1. Go to Firestore Database
2. Navigate to `users/{userId}/tasks` or `users/{userId}/notes`
3. Verify document fields match expected structure

#### Using Firebase CLI

```bash
# Export data for inspection
firebase firestore:export ./firestore-backup

# Query specific user's tasks
firebase firestore:query users/USER_ID/tasks
```

#### Programmatic Verification

```dart
Future<bool> verifyTaskSynced(String userId, Task localTask) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('tasks')
      .doc(localTask.firestoreId)
      .get();

  if (!doc.exists) return false;

  final data = doc.data()!;
  return data['title'] == localTask.title &&
         data['type'] == localTask.type &&
         data['isCompleted'] == localTask.isCompleted;
}
```

### Testing Offline/Online Transitions

**1. Simulate Offline Mode**

```dart
// In test code
await FirebaseFirestore.instance.disableNetwork();

// Perform operations (they queue locally)
await databaseService.saveTaskLocally(task);
await databaseService.syncTaskToCloud(task, userId);

// Re-enable network
await FirebaseFirestore.instance.enableNetwork();

// Verify sync occurred
await Future.delayed(Duration(seconds: 5));
// Check Firestore for the task
```

**2. Testing Sync Queue**

```dart
// Add task while "offline" (Firebase unavailable)
final task = Task(title: 'Offline Task', type: 'daily', createdAt: DateTime.now());
await databaseService.saveTaskLocally(task);

// Check pending sync count
final pendingCount = await databaseService.getPendingSyncCount();
expect(pendingCount, greaterThan(0));

// Force sync when back online
await databaseService.forceSyncPendingTasks();

// Verify sync completed
final newPendingCount = await databaseService.getPendingSyncCount();
expect(newPendingCount, 0);
```

**3. Sync Queue Behavior**

The sync queue uses exponential backoff:
- Attempt 1: 2 seconds delay
- Attempt 2: 4 seconds delay
- Attempt 3: 8 seconds delay
- After 3 failed attempts: item removed from queue
- Items older than 7 days: automatically removed

---

## 5. Common Issues and Solutions

### Port Conflicts with Emulators

**Issue:** Port 8080 already in use

**Solution:**
```bash
# Find process using port 8080
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # macOS/Linux

# Kill the process
taskkill /PID <PID> /F        # Windows
kill -9 <PID>                 # macOS/Linux

# Or use different ports in firebase.json
{
  "emulators": {
    "firestore": {
      "port": 8081
    },
    "auth": {
      "port": 9098
    }
  }
}
```

### Google Sign-In on Web (linkWithPopup Solution)

**Issue:** `google_sign_in` package doesn't reliably provide `idToken` on web platform.

**Solution:** Use `signInWithPopup` directly for web:

```dart
// In google_sign_in_service.dart
Future<UserCredential?> signInWithGoogle() async {
  if (kIsWeb) {
    // Use signInWithPopup for web (bypasses google_sign_in package limitation)
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
    return userCredential;
  }

  // Mobile: use google_sign_in package
  // ...
}
```

**For linking anonymous accounts on web:**
```dart
// In auth_service.dart - linkWithGoogle method
if (kIsWeb) {
  final googleProvider = GoogleAuthProvider();
  googleProvider.addScope('email');
  googleProvider.addScope('profile');

  // Use linkWithPopup instead of linkWithCredential
  final result = await currentUser.linkWithPopup(googleProvider);
  return (credential: result.credential, error: null);
}
```

### Missing Fields in Note Sync

**Issue:** Notes synced to Firestore were missing fields like `checklist`, `notebookId`, `status`, `richContent`, `contentType`.

**Root Cause:** The `toFirestore()` method wasn't including all fields.

**Solution:** Ensure `toFirestore()` includes all fields:

```dart
// In note_model.dart
Map<String, dynamic> toFirestore() {
  return {
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'taskId': taskId,
    'color': color,
    'isPinned': isPinned,
    'tags': tags,
    'deleted': deleted,
    'deletedAt': deletedAt?.toIso8601String(),
    'checklist': checklist.map((item) => item.toMap()).toList(),  // Added
    'notebookId': notebookId,                                      // Added
    'status': status,                                              // Added
    'richContent': richContent,                                    // Added
    'contentType': contentType,                                    // Added
  };
}
```

**Verification:** After fixing, all fields should appear in Firestore documents.

### Firestore Security Rules Blocking Writes

**Issue:** Writes fail with permission denied errors.

**Check rules:**
```bash
firebase deploy --only firestore:rules --dry-run
```

**Current rules location:** `firestore.rules`

**Debugging:**
1. Check Firebase Console > Firestore > Rules > Monitor
2. Look for denied requests and the rule that blocked them

### Task/Note Duplication

**Issue:** Same task/note appears multiple times after sync.

**Root Cause:** `copyWith()` creates new instances without Hive reference.

**Solution implemented in DatabaseService:**
```dart
Future<void> saveTaskLocally(Task task) async {
  if (task.isInBox) {
    await task.save();
  } else {
    // Check for existing task by firestoreId or createdAt
    final existing = await _findExistingTask(task);
    if (existing != null) {
      // Update existing instead of creating duplicate
      existing.updateInPlace(...);
      await existing.save();
      return;
    }
    await box.add(task);
  }
}
```

---

## 6. Continuation Guide for Future Agents

### Current State of the Sync System

**Architecture:**
- **Offline-First:** All data saved to Hive first, then synced to Firebase
- **Optimistic Updates:** UI updates immediately from Hive
- **Sync Queue:** Failed syncs queued with exponential backoff retry
- **Debounced Sync:** Multiple rapid changes batched before syncing

**Data Models Synced:**
- Tasks (typeId: 0) - Fully implemented
- Notes (typeId: 2) - Fully implemented (with checklist support)
- Notebooks (typeId: 6) - Implemented

**Authentication:**
- Anonymous auth (primary)
- Google Sign-In (for account linking/persistence)
- Email/Password (for account linking)

### Known Issues That Need Attention

1. **No Integration Tests**
   - Only unit tests exist
   - Need integration tests that verify end-to-end sync
   - Priority: HIGH

2. **Sync Conflict Resolution**
   - Basic last-write-wins implemented
   - More sophisticated conflict resolution may be needed
   - Priority: MEDIUM

3. **Real-time Listeners**
   - Currently uses one-time fetch for cloud data
   - Could implement Firestore listeners for real-time sync
   - Priority: LOW (app works offline-first anyway)

4. **Notebook Sync**
   - Implemented but less tested than tasks/notes
   - Verify notebook<->note relationships sync correctly
   - Priority: MEDIUM

5. **Rich Text Content**
   - `richContent` field stores Quill Delta JSON
   - Large documents may hit Firestore document size limits (1MB)
   - Priority: LOW

### Priority Items for Verification

When continuing work on Firebase sync:

1. **Verify Task Sync**
   ```dart
   // Create task locally
   // Enable cloud sync
   // Check task appears in Firestore
   // Modify task
   // Verify update in Firestore
   // Delete task
   // Verify soft delete in Firestore
   ```

2. **Verify Note Sync with Checklist**
   ```dart
   // Create note with checklist items
   // Sync to cloud
   // Verify checklist array in Firestore
   // Modify checklist
   // Verify update
   ```

3. **Verify Offline Queue**
   ```dart
   // Disable network
   // Create tasks/notes
   // Verify queue count > 0
   // Enable network
   // Wait for sync
   // Verify queue empty
   // Verify data in Firestore
   ```

4. **Verify Account Linking**
   ```dart
   // Start anonymous
   // Create data
   // Link with Google
   // Sign out
   // Sign in with Google
   // Verify data persisted
   ```

### Useful Commands

```bash
# Check current Firebase project
firebase projects:list

# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes

# View Firestore data
firebase firestore:query users --shallow

# Start emulators with data persistence
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Code Locations

| Component | Location |
|-----------|----------|
| Database Service | `lib/services/database_service.dart` |
| Auth Service | `lib/services/auth_service.dart` |
| Google Sign-In | `lib/services/google_sign_in_service.dart` |
| Task Model | `lib/models/task_model.dart` |
| Note Model | `lib/models/note_model.dart` |
| Notebook Model | `lib/models/notebook_model.dart` |
| Firestore Rules | `firestore.rules` |
| Firebase Config | `firebase.json` |
| Unit Tests | `test/` |

---

## Appendix: Quick Reference

### Firebase CLI Commands
```bash
firebase login                    # Authenticate
firebase use aura-list           # Select project
firebase emulators:start         # Start local emulators
firebase deploy                  # Deploy all
firebase deploy --only hosting   # Deploy web app
firebase deploy --only firestore # Deploy rules + indexes
```

### Flutter Test Commands
```bash
flutter test                              # All tests
flutter test --coverage                   # With coverage
flutter test test/services/              # Service tests only
flutter test -d chrome integration_test/ # Integration on web
```

### Useful Firestore Queries
```bash
# Get user's tasks
firebase firestore:query users/USER_ID/tasks

# Delete test data
firebase firestore:delete users/USER_ID --recursive
```
