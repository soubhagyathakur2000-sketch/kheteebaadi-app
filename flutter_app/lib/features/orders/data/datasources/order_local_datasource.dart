import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/orders/data/models/order_model.dart';

abstract class OrderLocalDataSource {
  Future<void> createOrder(OrderModel order);
  Future<OrderModel?> getOrderById(String id);
  Future<List<OrderModel>> getUserOrders(String userId);
  Future<List<OrderModel>> getPendingOrders(String userId);
  Future<void> updateOrder(OrderModel order);
  Future<void> markOrderAsSynced(String orderId);
  Future<void> deleteOrder(String id);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final AppDatabase _database;

  OrderLocalDataSourceImpl({required AppDatabase database}) : _database = database;

  @override
  Future<void> createOrder(OrderModel order) async {
    final itemsJson = OrderModel.itemsToJson(order.items);
    await _database.insertOrder(
      OrdersCompanion(
        id: Value(order.id),
        userId: Value(order.userId),
        itemsJson: Value(itemsJson),
        totalAmount: Value(order.totalAmount),
        status: Value(order.status),
        createdAt: Value(order.createdAt),
        updatedAt: Value(order.updatedAt),
        synced: Value(order.synced),
      ),
    );
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final entity = await _database.getOrderById(id);
    if (entity == null) return null;

    return OrderModel.fromDatabaseJson(
      entity.itemsJson,
      entity.id,
      entity.userId,
      entity.totalAmount,
      entity.status,
      entity.createdAt,
      entity.updatedAt,
      entity.synced,
    );
  }

  @override
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final entities = await _database.getUserOrders(userId);
    return entities
        .map((entity) => OrderModel.fromDatabaseJson(
              entity.itemsJson,
              entity.id,
              entity.userId,
              entity.totalAmount,
              entity.status,
              entity.createdAt,
              entity.updatedAt,
              entity.synced,
            ))
        .toList();
  }

  @override
  Future<List<OrderModel>> getPendingOrders(String userId) async {
    final entities = await _database.getPendingOrders();
    final userOrders = entities
        .where((entity) => entity.userId == userId)
        .toList();

    return userOrders
        .map((entity) => OrderModel.fromDatabaseJson(
              entity.itemsJson,
              entity.id,
              entity.userId,
              entity.totalAmount,
              entity.status,
              entity.createdAt,
              entity.updatedAt,
              entity.synced,
            ))
        .toList();
  }

  @override
  Future<void> updateOrder(OrderModel order) async {
    final itemsJson = OrderModel.itemsToJson(order.items);
    await _database.updateOrder(
      OrdersCompanion(
        id: Value(order.id),
        userId: Value(order.userId),
        itemsJson: Value(itemsJson),
        totalAmount: Value(order.totalAmount),
        status: Value(order.status),
        createdAt: Value(order.createdAt),
        updatedAt: Value(order.updatedAt),
        synced: Value(order.synced),
      ),
    );
  }

  @override
  Future<void> markOrderAsSynced(String orderId) async {
    await _database.markOrderAsSynced(orderId);
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _database.deleteOrder(id);
  }
}
