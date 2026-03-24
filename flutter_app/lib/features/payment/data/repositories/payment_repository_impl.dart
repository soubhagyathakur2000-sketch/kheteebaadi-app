import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';
import 'package:kheteebaadi/features/payment/domain/repositories/payment_repository.dart';
import 'package:kheteebaadi/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:kheteebaadi/features/payment/data/models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final AppDatabase database;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.database,
  });

  /// Layer 1: Write to PaymentsPending table before initiating
  @override
  Future<Payment> createPayment({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    try {
      // Create payment record in local DB first (Layer 1 Defense)
      final companion = PaymentsPendingCompanion(
        orderId: drift.Value(orderId),
        amount: drift.Value(amount),
        currency: drift.Value(currency),
        status: drift.Value(PaymentStatus.initiated.toJson()),
        pollCount: drift.Value(0),
        createdAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
      );

      final id = await database.into(database.paymentsPending).insert(companion);

      // Call remote API to create payment
      try {
        final remotePayment = await remoteDataSource.createPayment(
          orderId: orderId,
          amount: amount,
          currency: currency,
        );

        // Update local record with Razorpay order ID
        await database.update(database.paymentsPending).replace(
              PaymentsPendingCompanion(
                id: drift.Value(id),
                orderId: drift.Value(orderId),
                razorpayOrderId: drift.Value(remotePayment.razorpayOrderId),
                amount: drift.Value(amount),
                currency: drift.Value(currency),
                status: drift.Value(PaymentStatus.initiated.toJson()),
                pollCount: drift.Value(0),
                createdAt: drift.Value(DateTime.now()),
                updatedAt: drift.Value(DateTime.now()),
              ),
            );

        return remotePayment.copyWith(id: id);
      } catch (e) {
        // If remote fails, we still have local record for recovery (Layer 1)
        throw Exception('Failed to create payment: $e');
      }
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Verify payment with Razorpay and update local state
  @override
  Future<Payment> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      // Verify with remote API
      final payment = await remoteDataSource.verifyPayment(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      );

      // Update local record
      final existingPayment = await getPaymentByOrderId(orderId);
      if (existingPayment != null) {
        await updateLocalPayment(
          id: existingPayment.id,
          status: payment.status,
          razorpayPaymentId: payment.razorpayPaymentId,
          razorpaySignature: payment.razorpaySignature,
        );
      } else {
        await savePaymentLocally(payment);
      }

      return payment;
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Layer 2: Poll payment status on app resume
  /// Layer 3: Server-side webhook handling (client polls for updates)
  /// Layer 4: Scheduled reconciliation reference
  @override
  Future<Payment> checkPaymentStatus(String razorpayOrderId) async {
    try {
      // Fetch current status from API
      final payment = await remoteDataSource.checkPaymentStatus(razorpayOrderId);

      // Update local record
      final existingPayment = await getPaymentByOrderId(payment.orderId);
      if (existingPayment != null) {
        await updateLocalPayment(
          id: existingPayment.id,
          status: payment.status,
          razorpayPaymentId: payment.razorpayPaymentId,
          failureReason: payment.failureReason,
        );

        // Increment poll count
        await (database.paymentsPending.update()
              ..where((tbl) => tbl.id.equals(existingPayment.id)))
            .write(
              PaymentsPendingCompanion(
                pollCount: drift.Value(existingPayment.pollCount + 1),
                updatedAt: drift.Value(DateTime.now()),
              ),
            );
      }

      return payment;
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  /// Layer 5: Detect stuck payments
  @override
  Future<List<Payment>> getInitiatedPayments() async {
    final now = DateTime.now();
    final threshold = now.subtract(
      Duration(
        minutes: AppConstants.paymentStuckThresholdMinutes,
      ),
    );

    final entities = await (database.paymentsPending.select()
          ..where(
            (tbl) =>
                tbl.status.equals(PaymentStatus.initiated.toJson()) &
                tbl.createdAt.isSmallerThanValue(threshold),
          ))
        .get();

    return entities
        .map((e) => PaymentModel.fromPaymentPendingEntity(e).toEntity())
        .toList();
  }

  @override
  Future<void> updateLocalPayment({
    required int id,
    required PaymentStatus status,
    String? razorpayPaymentId,
    String? razorpaySignature,
    String? failureReason,
  }) async {
    await (database.paymentsPending.update()
          ..where((tbl) => tbl.id.equals(id)))
        .write(
          PaymentsPendingCompanion(
            status: drift.Value(status.toJson()),
            razorpayPaymentId: drift.Value(razorpayPaymentId),
            razorpaySignature: drift.Value(razorpaySignature),
            failureReason: drift.Value(failureReason),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> savePaymentLocally(Payment payment) async {
    final model = PaymentModel.fromEntity(payment);
    await database
        .into(database.paymentsPending)
        .insert(model.toCompanion());
  }

  @override
  Future<Payment?> getPaymentById(int id) async {
    try {
      final entity = await (database.paymentsPending.select()
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      return entity != null
          ? PaymentModel.fromPaymentPendingEntity(entity).toEntity()
          : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    try {
      final entity = await (database.paymentsPending.select()
            ..where((tbl) => tbl.orderId.equals(orderId)))
          .getSingleOrNull();
      return entity != null
          ? PaymentModel.fromPaymentPendingEntity(entity).toEntity()
          : null;
    } catch (e) {
      return null;
    }
  }
}

extension PaymentModelCopyWith on PaymentModel {
  PaymentModel copyWith({
    int? id,
    String? orderId,
    String? razorpayOrderId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? razorpayPaymentId,
    String? razorpaySignature,
    String? failureReason,
    int? pollCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      failureReason: failureReason ?? this.failureReason,
      pollCount: pollCount ?? this.pollCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
