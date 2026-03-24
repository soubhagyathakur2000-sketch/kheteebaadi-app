import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/features/sync/presentation/providers/sync_provider.dart';

class SyncStatusWidget extends ConsumerWidget {
  final double? size;

  const SyncStatusWidget({
    Key? key,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    return syncStatus.when(
      data: (status) {
        if (status.isSyncing) {
          return Tooltip(
            message: 'Syncing ${status.pendingCount} items...',
            child: SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2E7D32),
                ),
              ),
            ),
          );
        }

        if (status.syncedCount > 0) {
          return Tooltip(
            message: '${status.syncedCount} synced',
            child: Icon(
              Icons.check_circle,
              color: const Color(0xFF43A047),
              size: size,
            ),
          );
        }

        if (status.pendingCount > 0) {
          return Tooltip(
            message: '${status.pendingCount} pending',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: const Color(0xFFFFA726),
                  size: size,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA726),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      status.pendingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (status.failedItems.isNotEmpty) {
          return Tooltip(
            message: '${status.failedItems.length} failed',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  color: const Color(0xFFE53935),
                  size: size,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      status.failedItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Tooltip(
          message: 'All synced',
          child: Icon(
            Icons.check_circle,
            color: Colors.grey[300],
            size: size,
          ),
        );
      },
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(0xFF2E7D32),
          ),
        ),
      ),
      error: (error, stack) => Icon(
        Icons.error,
        color: const Color(0xFFE53935),
        size: size,
      ),
    );
  }
}
