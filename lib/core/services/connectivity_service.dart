import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitor service evaluating active network connections.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get onConnectionChanged => _connectionController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (_) {
      // Fallback
      _isOnline = false;
      _connectionController.add(false);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If results contains any result other than ConnectivityResult.none, we are online.
    final bool hasConnection = results.any((result) => result != ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      _connectionController.add(hasConnection);
    }
  }

  void dispose() {
    _connectionController.close();
  }
}
