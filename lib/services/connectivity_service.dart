import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Stream provider for connectivity status
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Provider for current connectivity status
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.isConnected;
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivityController = StreamController<bool>.broadcast();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = _isConnectedFromResults(results);
      _connectivityController?.add(isConnected);
    });
  }

  bool _isConnectedFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    if (_connectivityController == null) {
      _init();
    }
    return _connectivityController!.stream;
  }

  /// Check current connectivity status
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isConnectedFromResults(results);
  }

  /// Check if connected via WiFi
  Future<bool> get isConnectedViaWifi async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Check if connected via mobile data
  Future<bool> get isConnectedViaMobile async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
    _connectivityController = null;
  }
}
