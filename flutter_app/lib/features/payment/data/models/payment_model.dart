import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';
import 'package:kheteebaadi/database/app_database.dart';

class PaymentModel extends Payment {
  PaymentModel({
    required super.id,
    required super.orderId,
    super.razorpayOrderId,
    required super.amount,
    required super.currency,
    required super.status,
    super.razorpayPaymentId,
    super.razorpaySignature,
    super.failureReason,
    required super.pollCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      orderId: json['order_id'] as String,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      status: PaymentStatus.fromJson(json['status'] as String? ?? 'initiated'),
      razorpayPaymentId: json['razorpay_payment_id'] as String?,
      razorpaySignature: json['razorpay_signature'] as String?,
      failureReason: json['failure_reason'] as String?,
      pollCount: json['poll_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      id: payment.id,
      orderId: payment.orderId,
      razorpayOrderId: payment.razorpayOrderId,
      amount: payment.amount,
      currency: payment.currency,
      status: payment.status,
      razorpayPaymentId: payment.razorpayPaymentId,
      razorpaySignature: payment.razorpaySignature,
      failureReason: payment.failureReason,
      pollCount: payment.pollCount,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }

  factory PaymentModel.fromPaymentPendingEntity(PaymentPendingEntity entity) {
    return PaymentModel(
      id: entity.id,
      orderId: entity.orderId,
      razorpayOrderId: entity.razorpayOrderId,
      amount: entity.amount,
      currency: entity.currency,
      status: PaymentStatus.fromJson(entity.status),
      razorpayPaymentId: entity.razorpayPaymentId,
      razorpaySignature: entity.razorpaySignature,
      failureReason: entity.failureReason,
      pollCount: entity.pollCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'amount': amount,
      'currency': currency,
      'status': status.toJson(),
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'failure_reason': failureReason,
      'poll_count': pollCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentsPendingCompanion toCompanion() {
    return PaymentsPendingCompanion(
      id: drift.Value(id),
      orderId: drift.Value(orderId),
      razorpayOrderId: drift.Value(razorpayOrderId),
      amount: drift.Value(amount),
      currency: drift.Value(currency),
      status: drift.Value(status.toJson()),
      razorpayPaymentId: drift.Value(razorpayPaymentId),
      razorpaySignature: drift.Value(razorpaySignature),
      failureReason: drift.Value(failureReason),
      pollCount: drift.Value(pollCount),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );
  }

  Payment toEntity() => this;
}
