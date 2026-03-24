enum PaymentStatus {
  initiated,
  authorized,
  captured,
  failed,
  timeout,
  refundInitiated,
  refundCompleted,
}

extension PaymentStatusExtension on PaymentStatus {
  String toDisplayString() {
    switch (this) {
      case PaymentStatus.initiated:
        return 'Initiated';
      case PaymentStatus.authorized:
        return 'Authorized';
      case PaymentStatus.captured:
        return 'Captured';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.timeout:
        return 'Timeout';
      case PaymentStatus.refundInitiated:
        return 'Refund Initiated';
      case PaymentStatus.refundCompleted:
        return 'Refund Completed';
    }
  }

  String toJson() {
    return toString().split('.').last;
  }

  static PaymentStatus fromJson(String json) {
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => PaymentStatus.failed,
    );
  }
}

class Payment {
  final int id;
  final String orderId;
  final String? razorpayOrderId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? failureReason;
  final int pollCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.orderId,
    this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.failureReason,
    required this.pollCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSuccessful =>
      status == PaymentStatus.captured ||
      status == PaymentStatus.authorized;

  bool get isFailed =>
      status == PaymentStatus.failed || status == PaymentStatus.timeout;

  bool get isPending =>
      status == PaymentStatus.initiated ||
      status == PaymentStatus.authorized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId;

  @override
  int get hashCode => id.hashCode ^ orderId.hashCode;
}
