import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/orders/data/datasources/order_local_datasource.dart';
import 'package:kheteebaadi/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:kheteebaadi/features/orders/data/models/order_model.dart';
import 'package:kheteebaadi/features/orders/domain/entities/order_entity.dart';
import 'package:kheteebaadi/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;
  final OrderLocalDataSource _localDataSource;

  OrderRepositoryImpl({
    required OrderRemoteDataSource remoteDataSource,
    required OrderLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, OrderEntity>> createOrder(OrderEntity order) async {
    try {
      final orderModel = OrderModel(
        id: order.id,
        userId: order.userId,
        items: order.items,
        totalAmount: order.totalAmount,
        status: order.status,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        synced: false,
      );

      await _localDataSource.createOrder(orderModel);

      try {
        final remote = await _remoteDataSource.createOrder(orderModel);
        await _localDataSource.markOrderAsSynced(remote.id);
        return Right(remote);
      } catch (e) {
        return Right(orderModel);
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders(String userId) async {
    try {
      final local = await _localDataSource.getUserOrders(userId);

      try {
        final remote = await _remoteDataSource.getOrders(userId);
        for (final order in remote) {
          await _localDataSource.updateOrder(order);
        }
        return Right(remote);
      } catch (e) {
        if (local.isNotEmpty) {
          return Right(local);
        }
        rethrow;
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderDetail(String orderId) async {
    try {
      final local = await _localDataSource.getOrderById(orderId);

      try {
        final remote = await _remoteDataSource.getOrderDetail(orderId);
        await _localDataSource.updateOrder(remote);
        return Right(remote);
      } catch (e) {
        if (local != null) {
          return Right(local);
        }
        rethrow;
      }
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    try {
      await _remoteDataSource.cancelOrder(orderId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }
}
