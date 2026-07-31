import 'dart:async';
import 'connectivity_service.dart';
import 'local_storage_service.dart';

/// Define a contract for background synchronization tasks.
abstract class SyncTask {
  String get taskId;
  Future<bool> execute();
}

/// Service coordinating offline-first background synchronizations.
/// Listens to network changes and executes registered synchronization tasks when online.
class SyncService {
  final ConnectivityService _connectivityService;
  final LocalStorageService _localStorageService;
  final List<SyncTask> _syncTasks = [];
  
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  LocalStorageService get localStorage => _localStorageService;

  SyncService(
    this._connectivityService,
    this._localStorageService,
  ) {
    _initSyncListener();
  }

  /// Registers a task to be processed during synchronization cycles.
  void registerSyncTask(SyncTask task) {
    if (!_syncTasks.any((t) => t.taskId == task.taskId)) {
      _syncTasks.add(task);
    }
  }

  /// Listens to online status transitions to trigger sync.
  void _initSyncListener() {
    _connectivitySubscription = _connectivityService.onConnectionChanged.listen((isOnline) {
      if (isOnline) {
        triggerSync();
      }
    });
  }

  /// Triggers the execution of all registered sync tasks.
  Future<void> triggerSync() async {
    if (_isSyncing || !_connectivityService.isOnline) return;
    _isSyncing = true;

    try {
      for (final task in _syncTasks) {
        int retryCount = 0;
        bool success = false;
        
        // Simple retry strategy: Attempt execution up to 3 times
        while (!success && retryCount < 3) {
          try {
            success = await task.execute();
          } catch (_) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount * 2)); // Backoff
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
