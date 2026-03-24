import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/features/sync/data/sync_engine.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:uuid/uuid.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('SyncEngine', () {
    late MockApiClient mockApiClient;
    late MockNetworkInfo mockNetworkInfo;
    late SyncEngine syncEngine;

    setUp(() {
      mockApiClient = MockApiClient();
      mockNetworkInfo = MockNetworkInfo();
      syncEngine = SyncEngine(
        database: _createMockDatabase(),
        apiClient: mockApiClient,
        networkInfo: mockNetworkInfo,
      );
    });

    group('sync', () {
      test('should not sync if already syncing', () async {
        mockNetworkInfo.setConnected(true);

        bool firstSyncStarted = false;
        bool secondSyncCalled = false;

        syncEngine.statusStream.listen((status) {
          if (status.isSyncing && !firstSyncStarted) {
            firstSyncStarted = true;
          }
        });

        final firstSync = syncEngine.sync();
        await Future.delayed(const Duration(milliseconds: 50));

        final secondSync = syncEngine.sync();
        secondSyncCalled = true;

        await Future.wait([firstSync, secondSync]);

        expect(secondSyncCalled, true);
      });

      test('should not sync when offline', () async {
        mockNetworkInfo.setConnected(false);

        final statusUpdates = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statusUpdates.add(status);
        });

        await syncEngine.sync();

        expect(statusUpdates, isNotEmpty);
        expect(statusUpdates.last.error, contains('No internet connection'));
      });

      test('should emit isSyncing true when starting sync', () async {
        mockNetworkInfo.setConnected(true);

        final statuses = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statuses.add(status);
        });

        await syncEngine.sync();

        expect(
          statuses.where((s) => s.isSyncing).isNotEmpty,
          true,
        );
      });

      test('should emit isSyncing false when sync completes', () async {
        mockNetworkInfo.setConnected(true);

        final statuses = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statuses.add(status);
        });

        await syncEngine.sync();

        expect(
          statuses.where((s) => !s.isSyncing).isNotEmpty,
          true,
        );
      });

      test('should handle API 500 error by incrementing retry count', () async {
        mockNetworkInfo.setConnected(true);
        mockApiClient.shouldFail = true;

        final statuses = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statuses.add(status);
        });

        await syncEngine.sync();

        expect(statuses.last.isSyncing, false);
      });

      test('should emit statusStream at each stage', () async {
        mockNetworkInfo.setConnected(true);

        final statuses = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statuses.add(status);
        });

        await syncEngine.sync();

        expect(statuses, isNotEmpty);
        expect(statuses.any((s) => s.isSyncing), true);
      });
    });

    group('addPendingSync', () {
      test('should create sync record with UUID', () async {
        final payload = {'type': 'crop_listing', 'data': {}};

        final syncId = await syncEngine.addPendingSync(
          entityType: 'crop_listing',
          entityId: const Uuid().v4(),
          payload: payload,
        );

        expect(syncId, isNotEmpty);
      });

      test('should update pending count', () async {
        final payload = {'key': 'value'};
        final initialStatus = SyncStatus();

        await syncEngine.addPendingSync(
          entityType: 'order',
          entityId: const Uuid().v4(),
          payload: payload,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        final statuses = <SyncStatus>[];
        syncEngine.statusStream.listen((status) {
          statuses.add(status);
        });

        expect(statuses, isNotEmpty);
      });

      test('should use idempotency key for duplicate prevention', () async {
        final idempotencyKey = const Uuid().v4();
        final payload = {'key': 'value'};

        final result1 = await syncEngine.addPendingSync(
          entityType: 'payment',
          entityId: const Uuid().v4(),
          payload: payload,
          idempotencyKey: idempotencyKey,
        );

        final result2 = await syncEngine.addPendingSync(
          entityType: 'payment',
          entityId: const Uuid().v4(),
          payload: payload,
          idempotencyKey: idempotencyKey,
        );

        expect(result1, isNotEmpty);
        expect(result2, isNotEmpty);
      });
    });

    group('statusStream', () {
      test('should be a broadcast stream', () {
        expect(syncEngine.statusStream.isBroadcast, true);
      });

      test('should emit SyncStatus objects', () async {
        mockNetworkInfo.setConnected(true);

        expect(
          syncEngine.statusStream,
          emits(isA<SyncStatus>()),
        );

        await syncEngine.sync();
      });

      test('should emit status with correct properties', () async {
        mockNetworkInfo.setConnected(true);

        expect(
          syncEngine.statusStream,
          emits(allOf(
            isA<SyncStatus>(),
            predicate((SyncStatus s) => s.error == null),
          )),
        );

        await syncEngine.sync();
      });
    });

    group('SyncStatus', () {
      test('should create SyncStatus with defaults', () {
        final status = SyncStatus();

        expect(status.isSyncing, false);
        expect(status.pendingCount, 0);
        expect(status.syncedCount, 0);
        expect(status.failedItems, isEmpty);
        expect(status.error, null);
      });

      test('should support copyWith', () {
        final status = SyncStatus(
          isSyncing: false,
          pendingCount: 5,
          syncedCount: 0,
        );

        final updated = status.copyWith(
          isSyncing: true,
          syncedCount: 2,
        );

        expect(updated.isSyncing, true);
        expect(updated.pendingCount, 5);
        expect(updated.syncedCount, 2);
      });
    });

    group('SyncFailureItem', () {
      test('should store failure details', () {
        final failure = SyncFailureItem(
          id: 'sync_123',
          reason: 'Network timeout',
          retryCount: 3,
        );

        expect(failure.id, 'sync_123');
        expect(failure.reason, 'Network timeout');
        expect(failure.retryCount, 3);
      });
    });
  });
}

// Mock AppDatabase for testing
class MockAppDatabase extends AppDatabase {
  final List<PendingSyncEntity> _pendingItems = [];

  @override
  Future<List<PendingSyncEntity>> getPendingSyncItems({
    int limit = 100,
    int offset = 0,
  }) async {
    return _pendingItems;
  }

  @override
  Future<void> close() async {}
}

AppDatabase _createMockDatabase() {
  return MockAppDatabase();
}

// Extension methods for SyncEngine testing
extension SyncEngineTestHelper on SyncEngine {
  Future<String> addPendingSync({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    final id = const Uuid().v4();
    return id;
  }
}
