/// Feature Guías Celestiales (personajes místicos) — punto de entrada único.
///
/// Uso en cualquier parte de la app:
/// ```dart
/// import 'package:checklist_app/features/guides/guides.dart';
/// // Acceso a: Guide, BlessingDefinition, activeGuideProvider, GuideAvatar, etc.
/// ```
///
/// Incluye: modelo, catálogo, providers, tema, registro de bendiciones,
/// rutas de assets (imágenes, animaciones), widgets (avatar, selector).
library;

// Modelo (compartido en lib/models; re-exportado para API única)
export 'package:checklist_app/models/guide_model.dart';

// Datos del feature
export 'package:checklist_app/features/guides/data/guide_catalog.dart';
export 'package:checklist_app/features/guides/data/guide_asset_paths.dart';

// Providers
export 'package:checklist_app/features/guides/providers/active_guide_provider.dart';
export 'package:checklist_app/features/guides/providers/guide_theme_provider.dart';
export 'package:checklist_app/features/guides/providers/blessing_trigger_provider.dart';
export 'package:checklist_app/features/guides/providers/guide_voice_provider.dart';

// Servicios (registro de bendiciones, triggers y voz)
export 'package:checklist_app/services/guide_blessing_registry.dart';
export 'package:checklist_app/services/blessing_trigger_service.dart';
export 'package:checklist_app/services/guide_voice_service.dart';

// Widgets
export 'package:checklist_app/features/guides/widgets/guide_avatar.dart';
export 'package:checklist_app/features/guides/widgets/guide_selector_sheet.dart';
