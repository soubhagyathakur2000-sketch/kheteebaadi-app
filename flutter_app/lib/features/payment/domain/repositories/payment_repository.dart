import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';

abstract class PaymentRepository {
  Future<Payment> createPayment({
    required String orderId,
    required double amount,
    required String currency,
  });

  Future<Payment> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  });

  Future<Payment> checkPaymentStatus(String razorpayOrderId);

  Future<List<Payment>> getInitiatedPayments();

  Future<void> updateLocalPayment({
    required int id,
    required PaymentStatus status,
    String? razorpayPaymentId,
    String? razorpaySignature,
    String? failureReason,
  });

  Future<void> savePaymentLocally(Payment payment);

  Future<Payment?> getPaymentById(int id);

  Future<Payment?> getPaymentByOrderId(String orderId);
}
