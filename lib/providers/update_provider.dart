import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/update_info.dart';
import '../services/remote_config_service.dart';
import '../widgets/update_dialogs.dart';
import '../services/logger_service.dart';

/// Provider for update checking state
final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return await remoteConfig.checkForUpdates();
});

/// Provider to check for updates and show dialog if needed
/// This is a one-time check that runs at app startup
final updateCheckAndShowProvider = FutureProvider.autoDispose<void>((ref) async {
  // Get the remote config service
  final remoteConfig = ref.watch(remoteConfigServiceProvider);

  try {
    // Initialize remote config
    await remoteConfig.initialize();

    // Check for updates
    final updateInfo = await remoteConfig.checkForUpdates();

    if (updateInfo == null) {
      LoggerService().debug('Provider', '[UpdateCheck] No update info available');
      return;
    }

    if (!updateInfo.shouldShowUpdateDialog) {
      LoggerService().debug('Provider', '[UpdateCheck] App is up to date');
      return;
    }

    // Store update info to show dialog later (after build completes)
    ref.read(_pendingUpdateProvider.notifier).state = updateInfo;

    LoggerService().debug('Provider', '[UpdateCheck] Update available: $updateInfo');
  } catch (e) {
    LoggerService().debug('Provider', '[UpdateCheck] Error checking for updates: $e');
    // Silently fail - don't block app startup
  }
});

/// Private provider to hold pending update info
final _pendingUpdateProvider = StateProvider<UpdateInfo?>((ref) => null);

/// Provider to get the current platform
final currentPlatformProvider = Provider<String>((ref) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  return remoteConfig.getCurrentPlatform();
});

/// Widget to handle showing update dialogs
/// Should be placed high in the widget tree (e.g., in main scaffold)
class UpdateChecker extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateChecker({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    // Check for updates on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasShownDialog) return;

    // Trigger the update check
    final asyncValue = ref.read(updateCheckAndShowProvider);

    await asyncValue.when(
      data: (_) async {
        // Check if there's a pending update to show
        final updateInfo = ref.read(_pendingUpdateProvider);

        if (updateInfo != null && mounted) {
          _hasShownDialog = true;
          final platform = ref.read(currentPlatformProvider);

          // Show appropriate dialog based on update type
          if (updateInfo.isUpdateRequired) {
            await UpdateDialogs.showForceUpdateDialog(
              context,
              updateInfo,
              platform,
            );
          } else if (updateInfo.isUpdateAvailable) {
            await UpdateDialogs.showOptionalUpdateDialog(
              context,
              updateInfo,
              platform,
            );
          }

          // Clear pending update
          ref.read(_pendingUpdateProvider.notifier).state = null;
        }
      },
      loading: () {},
      error: (error, stack) {
        LoggerService().debug('Provider', '[UpdateChecker] Error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Manual update check function
/// Can be called from settings or other UI
Future<void> checkForUpdatesManually(WidgetRef ref, BuildContext context) async {
  if (!context.mounted) return;

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final remoteConfig = ref.read(remoteConfigServiceProvider);
    final updateInfo = await remoteConfig.checkForUpdates();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Dismiss loading

    if (updateInfo == null) {
      _showNoUpdateDialog(context);
      return;
    }

    if (!updateInfo.shouldShowUpdateDialog) {
      _showNoUpdateDialog(context);
      return;
    }

    final platform = ref.read(currentPlatformProvider);

    // Show appropriate dialog
    if (updateInfo.isUpdateRequired) {
      await UpdateDialogs.showForceUpdateDialog(
        context,
        updateInfo,
        platform,
      );
    } else if (updateInfo.isUpdateAvailable) {
      await UpdateDialogs.showOptionalUpdateDialog(
        context,
        updateInfo,
        platform,
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Dismiss loading

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo verificar actualizaciones'),
      ),
    );
  }
}

/// Show dialog when no updates are available
void _showNoUpdateDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 12),
          Text('Actualizado'),
        ],
      ),
      content: const Text(
        'Estás usando la última versión de AuraList.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
