import 'package:dio/dio.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<OrderModel> createOrder(OrderModel order);
  Future<List<OrderModel>> getOrders(String userId);
  Future<OrderModel> getOrderDetail(String orderId);
  Future<void> cancelOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _apiClient;

  OrderRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final itemsJson = OrderModel.itemsToJson(order.items);
      final response = await _apiClient.post(
        ApiConstants.createOrderEndpoint,
        data: {
          'items': order.items
              .map((item) => {
                    'crop_id': item.cropId,
                    'crop_name': item.cropName,
                    'quantity': item.quantity,
                    'unit_price': item.unitPrice,
                  })
              .toList(),
          'total_amount': order.totalAmount,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'Failed to create order',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final orderData = data['order'];
      if (orderData is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid order data');
      }

      return OrderModel.fromJson(orderData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getOrdersEndpoint,
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch orders',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final orders = data['orders'];
      if (orders is! List) {
        throw ServerFailure(message: 'Invalid orders data');
      }

      return orders
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.getOrderDetailEndpoint}/$orderId',
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to fetch order details',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final orderData = data['order'];
      if (orderData is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid order data');
      }

      return OrderModel.fromJson(orderData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.cancelOrderEndpoint}/$orderId',
      );

      if (response.statusCode != 200) {
        throw ServerFailure(
          message: 'Failed to cancel order',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: e.toString());
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutFailure(message: 'Request timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ServerFailure(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'Network error');
      default:
        return ServerFailure(message: error.message ?? 'Unknown error');
    }
  }
}
