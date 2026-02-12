import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist_app/features/guides/data/guide_catalog.dart';
import 'package:checklist_app/models/guide_model.dart';

const _keyActiveGuideId = 'active_guide_id';

/// Estado del ID del guía activo (null = sin guía; tema por defecto).
final activeGuideIdProvider =
    StateNotifierProvider<ActiveGuideIdNotifier, String?>((ref) {
  return ActiveGuideIdNotifier();
});

/// Notifier que persiste [activeGuideId] en SharedPreferences.
class ActiveGuideIdNotifier extends StateNotifier<String?> {
  ActiveGuideIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyActiveGuideId);
    if (id != null && id.isNotEmpty && getGuideById(id) != null) {
      state = id;
    }
  }

  Future<void> setActiveGuide(String? id) async {
    if (id != null && getGuideById(id) == null) return;
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_keyActiveGuideId);
    } else {
      await prefs.setString(_keyActiveGuideId, id);
    }
  }
}

/// Guía activo actual (desde catálogo). Null si no hay guía seleccionado o el ID no existe.
final activeGuideProvider = Provider<Guide?>((ref) {
  final id = ref.watch(activeGuideIdProvider);
  if (id == null || id.isEmpty) return null;
  return getGuideById(id);
});

/// IDs disponibles para el selector de guía.
final availableGuidesProvider = Provider<List<Guide>>((ref) {
  return kGuideCatalog;
});
