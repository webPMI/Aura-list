import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_manager.dart';

/// ListTile reutilizable para controlar la sincronizacion en la nube
class SyncToggleTile extends ConsumerStatefulWidget {
  final bool showSubtitle;
  final EdgeInsetsGeometry? contentPadding;

  const SyncToggleTile({
    super.key,
    this.showSubtitle = true,
    this.contentPadding,
  });

  @override
  ConsumerState<SyncToggleTile> createState() => _SyncToggleTileState();
}

class _SyncToggleTileState extends ConsumerState<SyncToggleTile> {
  bool _isLoading = true;
  bool _syncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSyncPreference();
  }

  Future<void> _loadSyncPreference() async {
    final authManager = ref.read(authManagerProvider);
    final enabled = await authManager.isSyncEnabled();
    if (mounted) {
      setState(() {
        _syncEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSync(bool value) async {
    setState(() => _isLoading = true);

    final authManager = ref.read(authManagerProvider);
    await authManager.setSyncEnabled(value);

    if (mounted) {
      setState(() {
        _syncEnabled = value;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Sincronizacion a la nube activada'
                : 'Sincronizacion a la nube desactivada',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = ref.watch(authManagerProvider);
    final isLinked = authManager.isLinkedAccount;

    return ListTile(
      contentPadding: widget.contentPadding,
      leading: Icon(
        _syncEnabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        color: _syncEnabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      title: const Text('Sincronizar a la nube'),
      subtitle: widget.showSubtitle
          ? Text(
              !isLinked
                  ? 'Vincula tu cuenta para activar'
                  : _syncEnabled
                      ? 'Tus datos se sincronizan con Firebase'
                      : 'Tus datos solo se guardan localmente',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _syncEnabled,
              onChanged: isLinked ? _toggleSync : null,
            ),
    );
  }
}

/// Widget compacto para mostrar estado de sync con boton de forzar
class SyncStatusTile extends ConsumerStatefulWidget {
  final EdgeInsetsGeometry? contentPadding;

  const SyncStatusTile({
    super.key,
    this.contentPadding,
  });

  @override
  ConsumerState<SyncStatusTile> createState() => _SyncStatusTileState();
}

class _SyncStatusTileState extends ConsumerState<SyncStatusTile> {
  bool _isSyncing = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final authManager = ref.read(authManagerProvider);
    final count = await authManager.getPendingSyncCount();
    if (mounted) {
      setState(() => _pendingCount = count);
    }
  }

  Future<void> _forceSync() async {
    setState(() => _isSyncing = true);

    final authManager = ref.read(authManagerProvider);
    await authManager.forceSyncPending();

    await _loadPendingCount();

    if (mounted) {
      setState(() => _isSyncing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronizacion completada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_pendingCount == 0) {
      return ListTile(
        contentPadding: widget.contentPadding,
        leading: Icon(Icons.cloud_done, color: colorScheme.primary),
        title: const Text('Todo sincronizado'),
        subtitle: Text(
          'Tus datos estan al dia',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: widget.contentPadding,
      leading: Icon(Icons.cloud_upload_outlined, color: colorScheme.tertiary),
      title: Text('$_pendingCount cambios pendientes'),
      subtitle: Text(
        'Toca para sincronizar ahora',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: _isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _forceSync,
              tooltip: 'Sincronizar ahora',
            ),
      onTap: _isSyncing ? null : _forceSync,
    );
  }
}
