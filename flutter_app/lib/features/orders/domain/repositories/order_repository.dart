import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/orders/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order);
  Future<Either<Failure, List<OrderEntity>>> getOrders(String userId);
  Future<Either<Failure, OrderEntity>> getOrderDetail(String orderId);
  Future<Either<Failure, void>> cancelOrder(String orderId);
}
