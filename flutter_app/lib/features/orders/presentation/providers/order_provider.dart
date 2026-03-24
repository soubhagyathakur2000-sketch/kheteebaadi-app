import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/features/orders/data/datasources/order_local_datasource.dart';
import 'package:kheteebaadi/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:kheteebaadi/features/orders/data/repositories/order_repository_impl.dart';
import 'package:kheteebaadi/features/orders/domain/entities/order_entity.dart';
import 'package:kheteebaadi/features/orders/domain/repositories/order_repository.dart';

// Data source providers
final orderRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderRemoteDataSourceImpl(apiClient: apiClient);
});

final orderLocalDataSourceProvider = FutureProvider((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return OrderLocalDataSourceImpl(database: database);
});

// Repository provider
final orderRepositoryProvider = FutureProvider<OrderRepository>((ref) async {
  final remote = ref.watch(orderRemoteDataSourceProvider);
  final local = await ref.watch(orderLocalDataSourceProvider.future);
  return OrderRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

// Orders state
class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;
  final String? error;
  final int unSyncedCount;

  OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.unSyncedCount = 0,
  });

  OrdersState copyWith({
    List<OrderEntity>? orders,
    bool? isLoading,
    String? error,
    int? unSyncedCount,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unSyncedCount: unSyncedCount ?? this.unSyncedCount,
    );
  }
}

// Orders notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderRepository _repository;
  final String _userId;

  OrdersNotifier({
    required OrderRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(OrdersState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getOrders(_userId);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (orders) {
        final unSynced = orders.where((o) => !o.synced).length;
        state = state.copyWith(
          isLoading: false,
          orders: orders,
          unSyncedCount: unSynced,
        );
      },
    );
  }

  Future<bool> createOrder(OrderEntity order) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createOrder(order);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (createdOrder) {
        state = state.copyWith(
          isLoading: false,
          orders: [createdOrder, ...state.orders],
          unSyncedCount: state.unSyncedCount + (!createdOrder.synced ? 1 : 0),
        );
        return true;
      },
    );
  }

  Future<void> refresh() async {
    await loadOrders();
  }
}

// Orders provider
final ordersProvider = StateNotifierProvider.family<
    OrdersNotifier,
    OrdersState,
    String>((ref, userId) async {
  final repository = await ref.watch(orderRepositoryProvider.future);
  final notifier = OrdersNotifier(
    repository: repository,
    userId: userId,
  );
  await notifier.loadOrders();
  return notifier;
});

// Order detail provider
final orderDetailProvider = FutureProvider.family<OrderEntity?, String>(
    (ref, orderId) async {
  final repository = await ref.watch(orderRepositoryProvider.future);
  final result = await repository.getOrderDetail(orderId);

  return result.fold(
    (failure) => null,
    (order) => order,
  );
});
