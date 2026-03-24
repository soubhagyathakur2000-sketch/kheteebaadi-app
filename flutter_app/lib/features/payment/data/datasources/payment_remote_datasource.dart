import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/features/payment/data/models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> createPayment({
    required String orderId,
    required double amount,
    required String currency,
  });

  Future<PaymentModel> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  });

  Future<PaymentModel> checkPaymentStatus(String razorpayOrderId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient apiClient;

  PaymentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaymentModel> createPayment({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.createPaymentEndpoint,
        data: {
          'order_id': orderId,
          'amount': amount,
          'currency': currency,
        },
      );
      return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<PaymentModel> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.verifyPaymentEndpoint,
        data: {
          'razorpay_payment_id': paymentId,
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
        },
      );
      return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  @override
  Future<PaymentModel> checkPaymentStatus(String razorpayOrderId) async {
    try {
      final response = await apiClient.get(
        ApiConstants.paymentStatusEndpoint,
        queryParameters: {'razorpay_order_id': razorpayOrderId},
      );
      return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }
}
