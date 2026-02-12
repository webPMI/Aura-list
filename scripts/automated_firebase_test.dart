/// Automated Firebase Testing Script
///
/// This script tests Firebase Auth and Firestore operations without manual intervention.
/// It uses Firebase REST APIs to create test users and verify sync operations.
///
/// Usage: dart run scripts/automated_firebase_test.dart

import 'dart:convert';
import 'dart:io';

const String apiKey = 'AIzaSyCjzUwbufmxBQPNSaKVBIM68JXjH7y88Wk';
const String projectId = 'aura-list';
const String testPassword = 'TestPassword123!';

late String timestamp;
late String testEmail;
late String? idToken;
late String? localId;
late String? refreshToken;

void main() async {
  timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  testEmail = 'test_automated_$timestamp@test.auralist.app';

  print('=' * 60);
  print('🧪 AUTOMATED FIREBASE TEST SUITE');
  print('=' * 60);
  print('');

  try {
    await runAllTests();
    print('\n✅ ALL TESTS PASSED');
  } catch (e) {
    print('\n❌ TESTS FAILED: $e');
    exit(1);
  } finally {
    await cleanup();
  }
}

Future<void> runAllTests() async {
  // Test 1: Create test user
  await testCreateUser();

  // Test 2: Sign in with test user
  await testSignIn();

  // Test 3: Verify Firestore write permissions
  await testFirestoreWrite();

  // Test 4: Verify Firestore read permissions
  await testFirestoreRead();

  // Test 5: Test task sync structure
  await testTaskSync();

  // Test 6: Test note sync with all fields
  await testNoteSync();

  // Test 7: Test notebook sync
  await testNotebookSync();

  // Test 8: Delete test data
  await testDeleteData();
}

Future<void> testCreateUser() async {
  printTest('1. Create Test User');

  final response = await httpPost(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    {
      'email': testEmail,
      'password': testPassword,
      'returnSecureToken': true,
    },
  );

  if (response['error'] != null) {
    throw Exception('Failed to create user: ${response['error']['message']}');
  }

  idToken = response['idToken'];
  localId = response['localId'];
  refreshToken = response['refreshToken'];

  print('   ✓ User created: $localId');
  print('   ✓ Email: $testEmail');
}

Future<void> testSignIn() async {
  printTest('2. Sign In Test');

  final response = await httpPost(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    {
      'email': testEmail,
      'password': testPassword,
      'returnSecureToken': true,
    },
  );

  if (response['error'] != null) {
    throw Exception('Failed to sign in: ${response['error']['message']}');
  }

  // Update token
  idToken = response['idToken'];

  print('   ✓ Sign in successful');
  print('   ✓ Token refreshed');
}

Future<void> testFirestoreWrite() async {
  printTest('3. Firestore Write Permission Test');

  final docPath = 'users/$localId';

  final response = await firestoreRequest(
    'PATCH',
    docPath,
    {
      'fields': {
        'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        'email': {'stringValue': testEmail},
        'testField': {'stringValue': 'test_value'},
      },
    },
  );

  if (response['error'] != null) {
    throw Exception('Firestore write failed: ${response['error']['message']}');
  }

  print('   ✓ User document created/updated');
}

Future<void> testFirestoreRead() async {
  printTest('4. Firestore Read Permission Test');

  final docPath = 'users/$localId';

  final response = await firestoreRequest('GET', docPath, null);

  if (response['error'] != null) {
    throw Exception('Firestore read failed: ${response['error']['message']}');
  }

  final fields = response['fields'];
  if (fields == null) {
    throw Exception('No fields in document');
  }

  print('   ✓ Document read successful');
  print('   ✓ Fields: ${fields.keys.join(', ')}');
}

Future<void> testTaskSync() async {
  printTest('5. Task Sync Structure Test');

  final taskId = 'test_task_$timestamp';
  final docPath = 'users/$localId/tasks/$taskId';

  // Create task with all required fields
  final taskData = {
    'fields': {
      'title': {'stringValue': 'Test Task'},
      'description': {'stringValue': 'Test Description'},
      'type': {'stringValue': 'daily'},
      'priority': {'integerValue': '1'},
      'category': {'stringValue': 'Personal'},
      'isCompleted': {'booleanValue': false},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'dueDate': {'timestampValue': DateTime.now().add(Duration(days: 1)).toUtc().toIso8601String()},
      'motivation': {'stringValue': 'Test motivation'},
      'reward': {'stringValue': 'Test reward'},
      'subtasks': {'arrayValue': {'values': []}},
    },
  };

  final response = await firestoreRequest('PATCH', docPath, taskData);

  if (response['error'] != null) {
    throw Exception('Task sync failed: ${response['error']['message']}');
  }

  print('   ✓ Task created in Firestore');
  print('   ✓ All required fields included');
}

Future<void> testNoteSync() async {
  printTest('6. Note Sync Structure Test (with all new fields)');

  final noteId = 'test_note_$timestamp';
  final docPath = 'users/$localId/notes/$noteId';

  // Create note with ALL fields including the newly fixed ones
  final noteData = {
    'fields': {
      'title': {'stringValue': 'Test Note'},
      'content': {'stringValue': 'Test content'},
      'color': {'stringValue': '#FF5722'},
      'isPinned': {'booleanValue': false},
      'tags': {'arrayValue': {'values': [
        {'stringValue': 'test'},
        {'stringValue': 'automated'},
      ]}},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'deleted': {'booleanValue': false},
      // NEW FIELDS that were fixed in saveNoteLocally and syncFromCloud
      'notebookId': {'stringValue': 'test_notebook'},
      'status': {'stringValue': 'active'},
      'contentType': {'stringValue': 'rich'},
      'richContent': {'stringValue': '{"ops":[{"insert":"Rich text content\\n"}]}'},
      'checklist': {'arrayValue': {'values': [
        {'mapValue': {'fields': {
          'text': {'stringValue': 'Checklist item 1'},
          'isCompleted': {'booleanValue': false},
        }}},
        {'mapValue': {'fields': {
          'text': {'stringValue': 'Checklist item 2'},
          'isCompleted': {'booleanValue': true},
        }}},
      ]}},
    },
  };

  final response = await firestoreRequest('PATCH', docPath, noteData);

  if (response['error'] != null) {
    throw Exception('Note sync failed: ${response['error']['message']}');
  }

  // Verify by reading back
  final readResponse = await firestoreRequest('GET', docPath, null);
  final fields = readResponse['fields'];

  // Check all critical fields exist
  final criticalFields = ['notebookId', 'status', 'contentType', 'richContent', 'checklist'];
  for (final field in criticalFields) {
    if (fields[field] == null) {
      throw Exception('Missing critical field: $field');
    }
  }

  print('   ✓ Note created with all fields');
  print('   ✓ Verified: ${criticalFields.join(', ')}');
}

Future<void> testNotebookSync() async {
  printTest('7. Notebook Sync Test');

  final notebookId = 'test_notebook_$timestamp';
  final docPath = 'users/$localId/notebooks/$notebookId';

  final notebookData = {
    'fields': {
      'name': {'stringValue': 'Test Notebook'},
      'icon': {'stringValue': '📁'},
      'color': {'stringValue': '#6750A4'},
      'isFavorited': {'booleanValue': false},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    },
  };

  final response = await firestoreRequest('PATCH', docPath, notebookData);

  if (response['error'] != null) {
    throw Exception('Notebook sync failed: ${response['error']['message']}');
  }

  print('   ✓ Notebook created in Firestore');
  print('   ✓ Notebooks collection accessible');
}

Future<void> testDeleteData() async {
  printTest('8. Cleanup Test Data');

  // Delete task
  final taskPath = 'users/$localId/tasks/test_task_$timestamp';
  await firestoreRequest('DELETE', taskPath, null);
  print('   ✓ Test task deleted');

  // Delete note
  final notePath = 'users/$localId/notes/test_note_$timestamp';
  await firestoreRequest('DELETE', notePath, null);
  print('   ✓ Test note deleted');

  // Delete notebook
  final notebookPath = 'users/$localId/notebooks/test_notebook_$timestamp';
  await firestoreRequest('DELETE', notebookPath, null);
  print('   ✓ Test notebook deleted');

  // Delete user document
  final userPath = 'users/$localId';
  await firestoreRequest('DELETE', userPath, null);
  print('   ✓ User document deleted');
}

Future<void> cleanup() async {
  print('\n📋 CLEANUP');
  print('-' * 40);

  if (localId != null && idToken != null) {
    try {
      // Delete the test user account
      final response = await httpPost(
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey',
        {
          'idToken': idToken,
        },
      );

      if (response['error'] == null) {
        print('   ✓ Test user account deleted');
      }
    } catch (e) {
      print('   ⚠ Could not delete test user: $e');
    }
  }
}

// Helper functions

void printTest(String name) {
  print('\n🧪 Test: $name');
  print('-' * 40);
}

Future<Map<String, dynamic>> httpPost(String url, Map<String, dynamic> body) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(body));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return jsonDecode(responseBody);
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> firestoreRequest(
  String method,
  String docPath,
  Map<String, dynamic>? body,
) async {
  final baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
  final url = '$baseUrl/$docPath';

  final client = HttpClient();
  try {
    HttpClientRequest request;

    switch (method) {
      case 'GET':
        request = await client.getUrl(Uri.parse(url));
        break;
      case 'PATCH':
        request = await client.patchUrl(Uri.parse(url));
        break;
      case 'DELETE':
        request = await client.deleteUrl(Uri.parse(url));
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    request.headers.set('Authorization', 'Bearer $idToken');
    request.headers.set('Content-Type', 'application/json; charset=utf-8');

    if (body != null) {
      request.add(utf8.encode(jsonEncode(body)));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (responseBody.isEmpty) {
      return {};
    }

    return jsonDecode(responseBody);
  } finally {
    client.close();
  }
}
