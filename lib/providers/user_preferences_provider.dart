import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/user_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider that emits the current UserPreferences and updates when they change.
final userPreferencesProvider = StreamProvider<UserPreferences>((ref) async* {
  final db = ref.read(databaseServiceProvider);
  await db.init();

  // Get initial preferences
  final initialPrefs = await db.getUserPreferences();
  yield initialPrefs;

  // Watch the box for changes
  // Note: the box name 'user_prefs' is hardcoded in DatabaseService
  final box = Hive.box<UserPreferences>('user_prefs');

  await for (final event in box.watch()) {
    yield await db.getUserPreferences();
  }
});
