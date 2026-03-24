import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../../features/auth/services/auth_service.dart';

/// Service for Firebase Crashlytics integration with custom error tracking
/// and application telemetry for the Kheteebaadi platform.
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();

  late final FirebaseCrashlytics _crashlytics;
  final Map<String, dynamic> _customKeys = {};
  DateTime? _lastSyncTime;
  int _pendingPaymentsCount = 0;

  factory CrashlyticsService() {
    return _instance;
  }

  CrashlyticsService._internal() {
    _crashlytics = FirebaseCrashlytics.instance;
  }

  /// Initialize Crashlytics service
  /// Should be called once during app startup before any other services
  Future<void> initialize() async {
    if (kDebugMode) {
      // In debug mode, log to console instead
      await _crashlytics.setCrashlyticsCollectionEnabled(false);
      debugPrint('Crashlytics disabled in debug mode');
    } else {
      // In production, enable Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Capture Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
      };

      // Capture async errors outside of Flutter
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }

    debugPrint('Crashlytics service initialized');
  }

  /// Set user identifier for error tracking and session correlation
  ///
  /// Parameters:
  ///   - userId: Unique identifier for the current user
  ///   - email: User's email (optional, for support)
  Future<void> setUserIdentifier({
    required String userId,
    String? email,
  }) async {
    try {
      _customKeys['user_id'] = userId;
      if (email != null) {
        _customKeys['email'] = email;
      }

      await _crashlytics.setUserIdentifier(userId);

      if (email != null) {
        await _crashlytics.setCustomKey('email', email);
      }

      debugPrint('Crashlytics user identifier set: $userId');
    } catch (e) {
      debugPrint('Error setting Crashlytics user identifier: $e');
    }
  }

  /// Clear user identifier (call on logout)
  Future<void> clearUserIdentifier() async {
    try {
      _customKeys.remove('user_id');
      _customKeys.remove('email');

      // Firebase doesn't have a direct clearUserIdentifier, so we reset with empty
      await _crashlytics.setUserIdentifier('');

      debugPrint('Crashlytics user identifier cleared');
    } catch (e) {
      debugPrint('Error clearing Crashlytics user identifier: $e');
    }
  }

  /// Record an error with stack trace
  ///
  /// Parameters:
  ///   - error: The exception or error object
  ///   - stackTrace: Stack trace for debugging
  ///   - reason: Human-readable description of the error context
  ///   - fatal: Whether this is a fatal/crash error
  ///   - context: Additional context information
  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Add context to custom keys temporarily
      if (context != null) {
        for (final entry in context.entries) {
          _customKeys['context_${entry.key}'] = entry.value;
        }
      }

      if (reason != null) {
        _customKeys['error_reason'] = reason;
      }

      // Record to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: reason,
        fatal: fatal,
        information: [],
      );

      if (kDebugMode) {
        debugPrint('[Crashlytics] Error recorded: $error');
        if (reason != null) {
          debugPrint('[Crashlytics] Reason: $reason');
        }
        if (stackTrace != null) {
          debugPrint('[Crashlytics] Stack: $stackTrace');
        }
      }
    } catch (e) {
      debugPrint('Error recording to Crashlytics: $e');
    }
  }

  /// Record a custom event with contextual information
  ///
  /// Parameters:
  ///   - eventName: Name of the event
  ///   - parameters: Event-specific parameters
  Future<void> recordEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Log event with custom key
      _customKeys['last_event'] = eventName;

      if (parameters != null) {
        for (final entry in parameters.entries) {
          _customKeys['event_${entry.key}'] = entry.value;
        }
      }

      if (kDebugMode) {
        debugPrint('[Crashlytics] Event: $eventName');
        if (parameters != null) {
          debugPrint('[Crashlytics] Parameters: $parameters');
        }
      }
    } catch (e) {
      debugPrint('Error recording event to Crashlytics: $e');
    }
  }

  /// Update current screen context
  ///
  /// Parameters:
  ///   - screenName: Name of the current screen/page
  Future<void> setCurrentScreen(String screenName) async {
    try {
      _customKeys['current_screen'] = screenName;
      await _crashlytics.setCustomKey('current_screen', screenName);

      if (kDebugMode) {
        debugPrint('[Crashlytics] Screen changed: $screenName');
      }
    } catch (e) {
      debugPrint('Error setting current screen: $e');
    }
  }

  /// Track sync operation status
  ///
  /// Parameters:
  ///   - isSyncing: Whether sync is currently in progress
  ///   - lastSyncTime: Timestamp of last successful sync
  ///   - pendingChanges: Number of pending changes to sync
  Future<void> updateSyncStatus({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingChanges,
  }) async {
    try {
      if (isSyncing != null) {
        _customKeys['sync_in_progress'] = isSyncing;
        await _crashlytics.setCustomKey('sync_in_progress', isSyncing);
      }

      if (lastSyncTime != null) {
        _lastSyncTime = lastSyncTime;
        _customKeys['last_sync_time'] = lastSyncTime.toIso8601String();
        await _crashlytics.setCustomKey(
          'last_sync_time',
          lastSyncTime.toIso8601String(),
        );
      }

      if (pendingChanges != null) {
        _customKeys['sync_queue_depth'] = pendingChanges;
        await _crashlytics.setCustomKey('sync_queue_depth', pendingChanges);
      }

      // Check for stalled sync
      _checkForStalledSync(pendingChanges);
    } catch (e) {
      debugPrint('Error updating sync status: $e');
    }
  }

  /// Track database metrics
  ///
  /// Parameters:
  ///   - dbSizeMb: Database file size in megabytes
  ///   - tableCount: Number of tables in database
  ///   - recordCount: Total records across all tables
  Future<void> updateDatabaseMetrics({
    double? dbSizeMb,
    int? tableCount,
    int? recordCount,
  }) async {
    try {
      if (dbSizeMb != null) {
        _customKeys['db_size_mb'] = dbSizeMb;
        await _crashlytics.setCustomKey('db_size_mb', dbSizeMb.toStringAsFixed(2));
      }

      if (tableCount != null) {
        _customKeys['db_table_count'] = tableCount;
        await _crashlytics.setCustomKey('db_table_count', tableCount);
      }

      if (recordCount != null) {
        _customKeys['db_record_count'] = recordCount;
        await _crashlytics.setCustomKey('db_record_count', recordCount);
      }
    } catch (e) {
      debugPrint('Error updating database metrics: $e');
    }
  }

  /// Track network status
  ///
  /// Parameters:
  ///   - networkType: Type of network (wifi, mobile, none)
  ///   - isConnected: Whether device has internet connectivity
  Future<void> updateNetworkStatus({
    String? networkType,
    bool? isConnected,
  }) async {
    try {
      if (networkType != null) {
        _customKeys['network_type'] = networkType;
        await _crashlytics.setCustomKey('network_type', networkType);
      }

      if (isConnected != null) {
        _customKeys['is_connected'] = isConnected;
        await _crashlytics.setCustomKey('is_connected', isConnected);
      }
    } catch (e) {
      debugPrint('Error updating network status: $e');
    }
  }

  /// Track payment operations
  ///
  /// Parameters:
  ///   - pendingPayments: Number of pending payments
  ///   - failedPayments: Number of failed payments
  Future<void> updatePaymentStatus({
    int? pendingPayments,
    int? failedPayments,
  }) async {
    try {
      if (pendingPayments != null) {
        _pendingPaymentsCount = pendingPayments;
        _customKeys['pending_payments_count'] = pendingPayments;
        await _crashlytics.setCustomKey('pending_payments_count', pendingPayments);
      }

      if (failedPayments != null) {
        _customKeys['failed_payments_count'] = failedPayments;
        await _crashlytics.setCustomKey('failed_payments_count', failedPayments);
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  /// Get all current custom key-value pairs
  Map<String, dynamic> getCustomKeys() {
    return Map.unmodifiable(_customKeys);
  }

  /// Log a message for debugging
  ///
  /// Parameters:
  ///   - message: The message to log
  ///   - level: Log level (debug, info, warning, error)
  void logMessage(
    String message, {
    String level = 'info',
  }) {
    try {
      if (kDebugMode) {
        debugPrint('[$level] $message');
      } else {
        // In production, we could send to a logging service
        // For now, just record as custom key
        _crashlytics.log(message);
      }
    } catch (e) {
      debugPrint('Error logging message: $e');
    }
  }

  /// Check if sync is stalled and record event
  ///
  /// Sync is considered stalled if:
  /// - There are pending changes (queue_depth > 0)
  /// - Last sync was more than 2 hours ago
  void _checkForStalledSync(int? pendingChanges) {
    try {
      if (pendingChanges == null || pendingChanges == 0) {
        return; // No pending changes, sync not stalled
      }

      if (_lastSyncTime == null) {
        return; // No sync history
      }

      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      const stallThreshold = Duration(hours: 2);

      if (timeSinceLastSync > stallThreshold) {
        // Sync is stalled - record event
        _crashlytics.recordError(
          Exception('Sync operation stalled'),
          StackTrace.current,
          reason: 'Pending changes: $pendingChanges, '
              'Last sync: ${_lastSyncTime?.toIso8601String()}',
          fatal: false,
        );

        _customKeys['sync_stalled'] = true;
        _customKeys['stall_duration_hours'] =
            timeSinceLastSync.inHours;

        if (kDebugMode) {
          debugPrint(
            '[Crashlytics] Sync stalled detected: '
            'Pending=$pendingChanges, '
            'Hours since sync=${timeSinceLastSync.inHours}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for stalled sync: $e');
    }
  }

  /// Clear all custom keys (useful for testing or after logout)
  Future<void> clearCustomKeys() async {
    try {
      _customKeys.clear();
      _lastSyncTime = null;
      _pendingPaymentsCount = 0;

      debugPrint('Crashlytics custom keys cleared');
    } catch (e) {
      debugPrint('Error clearing custom keys: $e');
    }
  }

  /// Dispose of resources (call during app shutdown)
  void dispose() {
    // Cleanup if needed
    debugPrint('Crashlytics service disposed');
  }
}

/// Extension to easily access Crashlytics from anywhere
extension CrashlyticsExtension on Object {
  CrashlyticsService get crashlytics => CrashlyticsService();
}
