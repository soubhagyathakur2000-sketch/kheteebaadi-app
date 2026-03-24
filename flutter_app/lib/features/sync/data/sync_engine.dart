import 'dart:convert';
import 'dart:async';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:uuid/uuid.dart';

class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final int syncedCount;
  final List<SyncFailureItem> failedItems;
  final String? error;

  SyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.failedItems = const [],
    this.error,
  });

  SyncStatus copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? syncedCount,
    List<SyncFailureItem>? failedItems,
    String? error,
  }) {
    return SyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      failedItems: failedItems ?? this.failedItems,
      error: error,
    );
  }
}

class SyncFailureItem {
  final String id;
  final String reason;
  final int retryCount;

  SyncFailureItem({
    required this.id,
    required this.reason,
    required this.retryCount,
  });
}

class SyncEngine {
  final AppDatabase _database;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _currentStatus = SyncStatus();

  SyncEngine({
    required AppDatabase database,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _database = database,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  Future<void> sync() async {
    if (_currentStatus.isSyncing) return;

    final isConnected = await _networkInfo.isConnected();
    if (!isConnected) {
      _updateStatus(
        _currentStatus.copyWith(
          error: 'No internet connection',
        ),
      );
      return;
    }

    _updateStatus(_currentStatus.copyWith(isSyncing: true, error: null));

    try {
      final pendingItems = await _database.getPendingSyncItems(
        limit: AppConstants.syncBatchSize,
      );

      if (pendingItems.isEmpty) {
        _updateStatus(_currentStatus.copyWith(isSyncing: false));
        return;
      }

      final batches = <List<PendingSyncEntity>>[];
      for (int i = 0; i < pendingItems.length; i += AppConstants.syncBatchSize) {
        batches.add(
          pendingItems.sublist(
            i,
            (i + AppConstants.syncBatchSize)
                .clamp(0, pendingItems.length),
          ),
        );
      }

      int totalSynced = 0;
      final failedItems = <SyncFailureItem>[];

      for (final batch in batches) {
        final result = await _syncBatch(batch);
        totalSynced += result.syncedCount;
        failedItems.addAll(result.failedItems);

        await Future.delayed(const Duration(milliseconds: 500));
      }

      final remainingPending = await _database.getPendingSyncItems();
      _updateStatus(
        _currentStatus.copyWith(
          isSyncing: false,
          syncedCount: totalSynced,
          pendingCount: remainingPending.length,
          failedItems: failedItems,
        ),
      );
    } catch (e) {
      _updateStatus(
        _currentStatus.copyWith(
          isSyncing: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<SyncBatchResult> _syncBatch(
      List<PendingSyncEntity> batch) async {
    try {
      final payload = batch
          .map((item) => {
                'id': item.id,
                'entity_type': item.entityType,
                'entity_id': item.entityId,
                'payload': jsonDecode(item.payloadJson),
                'idempotency_key': item.idempotencyKey,
              })
          .toList();

      try {
        final response = await _apiClient.post(
          ApiConstants.syncBatchEndpoint,
          data: {'items': payload},
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          return SyncBatchResult(
            syncedCount: 0,
            failedItems: batch
                .map((item) => SyncFailureItem(
                      id: item.id,
                      reason: 'Server error',
                      retryCount: item.retryCount,
                    ))
                .toList(),
          );
        }

        final responseData = response.data;
        if (responseData is! Map<String, dynamic>) {
          return SyncBatchResult(
            syncedCount: 0,
            failedItems: batch
                .map((item) => SyncFailureItem(
                      id: item.id,
                      reason: 'Invalid response',
                      retryCount: item.retryCount,
                    ))
                .toList(),
          );
        }

        final results = responseData['results'];
        if (results is! List) {
          return SyncBatchResult(
            syncedCount: 0,
            failedItems: batch
                .map((item) => SyncFailureItem(
                      id: item.id,
                      reason: 'Invalid results format',
                      retryCount: item.retryCount,
                    ))
                .toList(),
          );
        }

        int syncedCount = 0;
        final failedItems = <SyncFailureItem>[];

        for (final result in results.whereType<Map<String, dynamic>>()) {
          final itemId = result['id'] as String?;
          final success = result['success'] as bool? ?? false;
          final error = result['error'] as String?;

          if (itemId == null) continue;

          final batchItem = batch.firstWhere(
            (item) => item.id == itemId,
            orElse: () => throw StateError('Item not found: $itemId'),
          );

          if (success) {
            await _database.updatePendingSyncStatus(itemId, 'synced');
            syncedCount++;
          } else {
            if (batchItem.retryCount >= AppConstants.maxRetryCount) {
              await _database.updatePendingSyncStatus(
                itemId,
                'failed',
                failureReason: error ?? 'Max retries exceeded',
              );
              failedItems.add(
                SyncFailureItem(
                  id: itemId,
                  reason: error ?? 'Max retries exceeded',
                  retryCount: batchItem.retryCount,
                ),
              );
            } else {
              await _database.incrementPendingSyncRetryCount(itemId);
            }
          }
        }

        return SyncBatchResult(
          syncedCount: syncedCount,
          failedItems: failedItems,
        );
      } catch (e) {
        if (e.toString().contains('Connection')) {
          for (final item in batch) {
            await _database.incrementPendingSyncRetryCount(item.id);
          }
        }

        return SyncBatchResult(
          syncedCount: 0,
          failedItems: batch
              .map((item) => SyncFailureItem(
                    id: item.id,
                    reason: e.toString(),
                    retryCount: item.retryCount,
                  ))
              .toList(),
        );
      }
    } catch (e) {
      return SyncBatchResult(
        syncedCount: 0,
        failedItems: batch
            .map((item) => SyncFailureItem(
                  id: item.id,
                  reason: e.toString(),
                  retryCount: item.retryCount,
                ))
            .toList(),
      );
    }
  }

  Future<void> addPendingSync({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? const Uuid().v4();

    await _database.insertPendingSync(
      PendingSyncCompanion(
        id: Value(const Uuid().v4()),
        entityType: Value(entityType),
        entityId: Value(entityId),
        payloadJson: Value(jsonEncode(payload)),
        idempotencyKey: Value(key),
        createdAt: Value(DateTime.now()),
        status: Value('pending'),
      ),
    );

    final pending = await _database.getPendingSyncItems();
    _updateStatus(
      _currentStatus.copyWith(pendingCount: pending.length),
    );
  }

  Future<void> clearSyncedItems() async {
    await _database.clearSyncedItems();
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _statusController.close();
  }
}

class SyncBatchResult {
  final int syncedCount;
  final List<SyncFailureItem> failedItems;

  SyncBatchResult({
    required this.syncedCount,
    required this.failedItems,
  });
}
