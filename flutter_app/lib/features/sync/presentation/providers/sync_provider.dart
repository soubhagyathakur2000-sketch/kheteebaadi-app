import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/features/sync/data/sync_engine.dart';

// Sync engine provider
final syncEngineProvider = FutureProvider((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final apiClient = ref.watch(apiClientProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return SyncEngine(
    database: database,
    apiClient: apiClient,
    networkInfo: networkInfo,
  );
});

// Sync status stream provider
final syncStatusProvider = StreamProvider((ref) async* {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  yield* syncEngine.statusStream;
});

// Sync notifier for manual sync trigger
class SyncNotifier extends StateNotifier<void> {
  final SyncEngine _syncEngine;

  SyncNotifier({required SyncEngine syncEngine})
      : _syncEngine = syncEngine,
        super(null);

  Future<void> performSync() async {
    await _syncEngine.sync();
  }

  Future<void> addPendingSync({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    String? idempotencyKey,
  }) async {
    await _syncEngine.addPendingSync(
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> clearSynced() async {
    await _syncEngine.clearSyncedItems();
  }
}

// Sync control provider
final syncControlProvider =
    StateNotifierProvider.autoDispose<SyncNotifier, void>((ref) async {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  return SyncNotifier(syncEngine: syncEngine);
});

// Helper provider to check if there are pending items
final hasPendingSyncProvider = StreamProvider((ref) async* {
  final syncStatus = ref.watch(syncStatusProvider);
  yield* syncStatus.map((event) => event.maybeWhen(
        data: (status) => status.pendingCount > 0,
        orElse: () => false,
      ));
});

// Helper provider to get pending count
final pendingSyncCountProvider = StreamProvider((ref) async* {
  final syncStatus = ref.watch(syncStatusProvider);
  yield* syncStatus.map((event) => event.maybeWhen(
        data: (status) => status.pendingCount,
        orElse: () => 0,
      ));
});
