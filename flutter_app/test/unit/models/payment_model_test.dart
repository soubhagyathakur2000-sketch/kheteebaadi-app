import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/features/payment/data/models/payment_model.dart';
import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';

void main() {
  group('PaymentModel', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('should create instance with all fields present', () {
        final json = {
          'id': 1,
          'order_id': 'order_123',
          'razorpay_order_id': 'rpay_order_456',
          'amount': 5000.0,
          'currency': 'INR',
          'status': 'captured',
          'razorpay_payment_id': 'rpay_pay_789',
          'razorpay_signature': 'signature_xyz',
          'failure_reason': null,
          'poll_count': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = PaymentModel.fromJson(json);

        expect(model.id, 1);
        expect(model.orderId, 'order_123');
        expect(model.razorpayOrderId, 'rpay_order_456');
        expect(model.amount, 5000.0);
        expect(model.currency, 'INR');
        expect(model.status, PaymentStatus.captured);
        expect(model.razorpayPaymentId, 'rpay_pay_789');
        expect(model.razorpaySignature, 'signature_xyz');
        expect(model.failureReason, null);
        expect(model.pollCount, 0);
      });

      test('should use defaults for null optional fields', () {
        final json = {
          'id': 2,
          'order_id': 'order_456',
          'amount': 1000.0,
          'status': 'initiated',
          'poll_count': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = PaymentModel.fromJson(json);

        expect(model.razorpayOrderId, null);
        expect(model.razorpayPaymentId, null);
        expect(model.razorpaySignature, null);
        expect(model.failureReason, null);
        expect(model.currency, 'INR');
      });

      test('should default currency to INR when null', () {
        final json = {
          'id': 3,
          'order_id': 'order_789',
          'amount': 2000.0,
          'status': 'authorized',
          'poll_count': 1,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = PaymentModel.fromJson(json);

        expect(model.currency, 'INR');
      });

      test('should default poll_count to 0 when null', () {
        final json = {
          'id': 4,
          'order_id': 'order_abc',
          'amount': 3000.0,
          'currency': 'INR',
          'status': 'initiated',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final model = PaymentModel.fromJson(json);

        expect(model.pollCount, 0);
      });
    });

    group('PaymentStatus.fromJson', () {
      test('should parse "initiated" status', () {
        expect(
          PaymentStatus.fromJson('initiated'),
          PaymentStatus.initiated,
        );
      });

      test('should parse "authorized" status', () {
        expect(
          PaymentStatus.fromJson('authorized'),
          PaymentStatus.authorized,
        );
      });

      test('should parse "captured" status', () {
        expect(
          PaymentStatus.fromJson('captured'),
          PaymentStatus.captured,
        );
      });

      test('should parse "failed" status', () {
        expect(
          PaymentStatus.fromJson('failed'),
          PaymentStatus.failed,
        );
      });

      test('should parse "timeout" status', () {
        expect(
          PaymentStatus.fromJson('timeout'),
          PaymentStatus.timeout,
        );
      });

      test('should parse "refundInitiated" status', () {
        expect(
          PaymentStatus.fromJson('refundInitiated'),
          PaymentStatus.refundInitiated,
        );
      });

      test('should parse "refundCompleted" status', () {
        expect(
          PaymentStatus.fromJson('refundCompleted'),
          PaymentStatus.refundCompleted,
        );
      });

      test('should default to failed for unknown status string', () {
        expect(
          PaymentStatus.fromJson('unknown_status'),
          PaymentStatus.failed,
        );
        expect(
          PaymentStatus.fromJson(''),
          PaymentStatus.failed,
        );
      });
    });

    group('PaymentStatus.toJson and round-trip', () {
      test('should convert status to string and back correctly', () {
        final statuses = [
          PaymentStatus.initiated,
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.failed,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final status in statuses) {
          final jsonString = status.toJson();
          final restored = PaymentStatus.fromJson(jsonString);
          expect(restored, status, reason: 'Failed for status: $status');
        }
      });
    });

    group('Payment.isSuccessful', () {
      test('should return true for captured status', () {
        final payment = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.captured,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isSuccessful, true);
      });

      test('should return true for authorized status', () {
        final payment = PaymentModel(
          id: 2,
          orderId: 'order_456',
          amount: 2000.0,
          currency: 'INR',
          status: PaymentStatus.authorized,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isSuccessful, true);
      });

      test('should return false for other statuses', () {
        final statuses = [
          PaymentStatus.initiated,
          PaymentStatus.failed,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final status in statuses) {
          final payment = PaymentModel(
            id: 1,
            orderId: 'order_123',
            amount: 1000.0,
            currency: 'INR',
            status: status,
            pollCount: 0,
            createdAt: now,
            updatedAt: now,
          );

          expect(payment.isSuccessful, false, reason: 'Failed for status: $status');
        }
      });
    });

    group('Payment.isFailed', () {
      test('should return true for failed status', () {
        final payment = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.failed,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isFailed, true);
      });

      test('should return true for timeout status', () {
        final payment = PaymentModel(
          id: 2,
          orderId: 'order_456',
          amount: 2000.0,
          currency: 'INR',
          status: PaymentStatus.timeout,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isFailed, true);
      });

      test('should return false for other statuses', () {
        final statuses = [
          PaymentStatus.initiated,
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final status in statuses) {
          final payment = PaymentModel(
            id: 1,
            orderId: 'order_123',
            amount: 1000.0,
            currency: 'INR',
            status: status,
            pollCount: 0,
            createdAt: now,
            updatedAt: now,
          );

          expect(payment.isFailed, false, reason: 'Failed for status: $status');
        }
      });
    });

    group('Payment.isPending', () {
      test('should return true for initiated status', () {
        final payment = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.initiated,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isPending, true);
      });

      test('should return true for authorized status', () {
        final payment = PaymentModel(
          id: 2,
          orderId: 'order_456',
          amount: 2000.0,
          currency: 'INR',
          status: PaymentStatus.authorized,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment.isPending, true);
      });

      test('should return false for other statuses', () {
        final statuses = [
          PaymentStatus.captured,
          PaymentStatus.failed,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final status in statuses) {
          final payment = PaymentModel(
            id: 1,
            orderId: 'order_123',
            amount: 1000.0,
            currency: 'INR',
            status: status,
            pollCount: 0,
            createdAt: now,
            updatedAt: now,
          );

          expect(payment.isPending, false, reason: 'Failed for status: $status');
        }
      });
    });

    group('toJson and round-trip', () {
      test('should convert to JSON and back with all fields', () {
        final original = PaymentModel(
          id: 1,
          orderId: 'order_123',
          razorpayOrderId: 'rpay_order_456',
          amount: 5000.0,
          currency: 'INR',
          status: PaymentStatus.captured,
          razorpayPaymentId: 'rpay_pay_789',
          razorpaySignature: 'signature_xyz',
          failureReason: null,
          pollCount: 2,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = PaymentModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.orderId, original.orderId);
        expect(restored.razorpayOrderId, original.razorpayOrderId);
        expect(restored.amount, original.amount);
        expect(restored.currency, original.currency);
        expect(restored.status, original.status);
        expect(restored.razorpayPaymentId, original.razorpayPaymentId);
        expect(restored.razorpaySignature, original.razorpaySignature);
        expect(restored.pollCount, original.pollCount);
      });

      test('should handle null optional fields in round-trip', () {
        final original = PaymentModel(
          id: 2,
          orderId: 'order_456',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.initiated,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final restored = PaymentModel.fromJson(json);

        expect(restored.razorpayOrderId, null);
        expect(restored.razorpayPaymentId, null);
        expect(restored.razorpaySignature, null);
        expect(restored.failureReason, null);
      });
    });

    group('Payment equality', () {
      test('should consider payments equal if id and orderId match', () {
        final payment1 = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.initiated,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        final payment2 = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 2000.0,
          currency: 'USD',
          status: PaymentStatus.captured,
          pollCount: 5,
          createdAt: now.add(const Duration(days: 1)),
          updatedAt: now.add(const Duration(days: 1)),
        );

        expect(payment1, payment2);
      });

      test('should consider payments unequal if id differs', () {
        final payment1 = PaymentModel(
          id: 1,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.initiated,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        final payment2 = PaymentModel(
          id: 2,
          orderId: 'order_123',
          amount: 1000.0,
          currency: 'INR',
          status: PaymentStatus.initiated,
          pollCount: 0,
          createdAt: now,
          updatedAt: now,
        );

        expect(payment1, isNot(payment2));
      });
    });
  });
}
