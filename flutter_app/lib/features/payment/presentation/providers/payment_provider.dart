import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';
import 'package:kheteebaadi/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:kheteebaadi/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:kheteebaadi/features/payment/domain/repositories/payment_repository.dart';

// Database provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// API Client provider
final paymentApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Remote datasource provider
final paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSourceImpl(
    apiClient: ref.watch(paymentApiClientProvider),
  );
});

// Repository provider
final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

// Payment state notifier
class PaymentNotifier extends StateNotifier<Payment?> {
  final PaymentRepository repository;
  Timer? _pollTimer;
  int _pollAttempts = 0;

  PaymentNotifier({required this.repository}) : super(null);

  /// Initiate a new payment
  Future<void> initiatePayment({
    required String orderId,
    required double amount,
  }) async {
    try {
      final payment = await repository.createPayment(
        orderId: orderId,
        amount: amount,
        currency: 'INR',
      );
      state = payment;
      _resetPollCounter();
    } catch (e) {
      state = null;
      throw Exception('Failed to initiate payment: $e');
    }
  }

  /// Handle successful payment verification
  Future<void> onPaymentSuccess({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      _stopPolling();

      final payment = await repository.verifyPayment(
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
        signature: razorpaySignature,
      );

      state = payment;
    } catch (e) {
      throw Exception('Failed to verify payment: $e');
    }
  }

  /// Handle payment failure
  Future<void> onPaymentFailure({
    required String errorCode,
    required String errorDescription,
  }) async {
    try {
      _stopPolling();

      if (state != null) {
        await repository.updateLocalPayment(
          id: state!.id,
          status: PaymentStatus.failed,
          failureReason: '$errorCode: $errorDescription',
        );

        state = state!.copyWith(
          status: PaymentStatus.failed,
          failureReason: '$errorCode: $errorDescription',
        );
      }
    } catch (e) {
      throw Exception('Failed to handle payment failure: $e');
    }
  }

  /// Handle external wallet selection
  Future<void> onExternalWalletSelected({
    required String walletName,
  }) async {
    // Wallet selected but not yet processed
    // Payment will be completed through checkout
  }

  /// Check pending payments on app resume (Layer 2)
  Future<void> checkPendingPayments() async {
    try {
      final pendingPayments = await repository.getInitiatedPayments();

      for (final payment in pendingPayments) {
        await pollPaymentStatus(payment.razorpayOrderId ?? '');
      }
    } catch (e) {
      // Silently fail to not interrupt user experience
    }
  }

  /// Poll payment status (Layer 2 & 3 combined)
  Future<void> pollPaymentStatus(String razorpayOrderId) async {
    if (razorpayOrderId.isEmpty) return;

    _resetPollCounter();

    _pollTimer = Timer.periodic(
      Duration(
        seconds: AppConstants.paymentPollIntervalSeconds,
      ),
      (_) async {
        if (_pollAttempts >= AppConstants.paymentMaxPollAttempts) {
          _stopPolling();
          return;
        }

        try {
          final payment = await repository.checkPaymentStatus(razorpayOrderId);

          if (payment.isSuccessful) {
            state = payment;
            _stopPolling();
          } else if (payment.isFailed) {
            state = payment;
            _stopPolling();
          }

          _pollAttempts++;
        } catch (e) {
          _pollAttempts++;
          if (_pollAttempts >= AppConstants.paymentMaxPollAttempts) {
            _stopPolling();
            // Mark as timeout
            if (state != null) {
              state = state!.copyWith(
                status: PaymentStatus.timeout,
              );
            }
          }
        }
      },
    );
  }

  /// Stop polling
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Reset poll counter
  void _resetPollCounter() {
    _pollAttempts = 0;
  }

  /// Retry payment check
  Future<void> retryPaymentCheck() async {
    if (state != null && state!.razorpayOrderId != null) {
      await pollPaymentStatus(state!.razorpayOrderId!);
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

// Payment notifier provider
final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, Payment?>((ref) {
  return PaymentNotifier(
    repository: ref.watch(paymentRepositoryProvider),
  );
});

extension PaymentCopyWith on Payment {
  Payment copyWith({
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
    return Payment(
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
