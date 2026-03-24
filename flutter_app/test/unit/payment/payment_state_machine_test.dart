import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';

void main() {
  group('PaymentStateMachine', () {
    group('valid transitions', () {
      test('should allow initiated -> authorized', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.authorized,
          ),
          true,
        );
      });

      test('should allow initiated -> failed', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.failed,
          ),
          true,
        );
      });

      test('should allow initiated -> timeout', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.timeout,
          ),
          true,
        );
      });

      test('should allow authorized -> captured', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.authorized,
            PaymentStatus.captured,
          ),
          true,
        );
      });

      test('should allow authorized -> failed', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.authorized,
            PaymentStatus.failed,
          ),
          true,
        );
      });

      test('should allow captured -> refundInitiated', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.captured,
            PaymentStatus.refundInitiated,
          ),
          true,
        );
      });

      test('should allow refundInitiated -> refundCompleted', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.refundInitiated,
            PaymentStatus.refundCompleted,
          ),
          true,
        );
      });

      test('should allow timeout -> initiated (retry)', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.timeout,
            PaymentStatus.initiated,
          ),
          true,
        );
      });
    });

    group('invalid transitions', () {
      test('should not allow captured -> initiated', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.captured,
            PaymentStatus.initiated,
          ),
          false,
        );
      });

      test('should not allow captured -> authorized', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.captured,
            PaymentStatus.authorized,
          ),
          false,
        );
      });

      test('should not allow failed -> captured', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.failed,
            PaymentStatus.captured,
          ),
          false,
        );
      });

      test('should not allow failed -> authorized', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.failed,
            PaymentStatus.authorized,
          ),
          false,
        );
      });

      test('should not allow failed -> initiated', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.failed,
            PaymentStatus.initiated,
          ),
          false,
        );
      });

      test('should not allow refundCompleted -> any state', () {
        final terminal = PaymentStatus.refundCompleted;
        final otherStates = [
          PaymentStatus.initiated,
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.failed,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
        ];

        for (final state in otherStates) {
          expect(
            PaymentStateMachine.canTransition(terminal, state),
            false,
            reason: 'Should not transition from refundCompleted to $state',
          );
        }
      });

      test('should not allow refundInitiated -> initiated', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.refundInitiated,
            PaymentStatus.initiated,
          ),
          false,
        );
      });

      test('should not allow refundInitiated -> captured', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.refundInitiated,
            PaymentStatus.captured,
          ),
          false,
        );
      });
    });

    group('terminal states', () {
      test('should not transition from failed state', () {
        final failed = PaymentStatus.failed;
        final targetStates = [
          PaymentStatus.initiated,
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final state in targetStates) {
          expect(
            PaymentStateMachine.canTransition(failed, state),
            false,
            reason: 'Failed is terminal, should not go to $state',
          );
        }
      });

      test('should not transition from refundCompleted state', () {
        final refunded = PaymentStatus.refundCompleted;
        final targetStates = [
          PaymentStatus.initiated,
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.failed,
          PaymentStatus.timeout,
          PaymentStatus.refundInitiated,
        ];

        for (final state in targetStates) {
          expect(
            PaymentStateMachine.canTransition(refunded, state),
            false,
            reason: 'RefundCompleted is terminal, should not go to $state',
          );
        }
      });
    });

    group('happy path scenarios', () {
      test('should complete happy path: initiated -> authorized -> captured', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.authorized,
          ),
          true,
        );

        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.authorized,
            PaymentStatus.captured,
          ),
          true,
        );
      });

      test('should complete refund path: captured -> refundInitiated -> refundCompleted',
          () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.captured,
            PaymentStatus.refundInitiated,
          ),
          true,
        );

        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.refundInitiated,
            PaymentStatus.refundCompleted,
          ),
          true,
        );
      });

      test('should allow payment failure path: initiated -> failed', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.failed,
          ),
          true,
        );
      });

      test('should allow timeout and retry: initiated -> timeout -> initiated', () {
        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.initiated,
            PaymentStatus.timeout,
          ),
          true,
        );

        expect(
          PaymentStateMachine.canTransition(
            PaymentStatus.timeout,
            PaymentStatus.initiated,
          ),
          true,
        );
      });
    });

    group('edge cases', () {
      test('should handle same state transition (identity)', () {
        final status = PaymentStatus.initiated;
        expect(
          PaymentStateMachine.canTransition(status, status),
          false,
        );
      });

      test('should not allow any transition to initiated except from timeout', () {
        final sourcesNotAllowed = [
          PaymentStatus.authorized,
          PaymentStatus.captured,
          PaymentStatus.failed,
          PaymentStatus.refundInitiated,
          PaymentStatus.refundCompleted,
        ];

        for (final source in sourcesNotAllowed) {
          expect(
            PaymentStateMachine.canTransition(source, PaymentStatus.initiated),
            false,
            reason: 'Should not transition from $source to initiated',
          );
        }
      });

      test('should handle all PaymentStatus enum values', () {
        final allStatuses = PaymentStatus.values;

        for (final from in allStatuses) {
          for (final to in allStatuses) {
            final result = PaymentStateMachine.canTransition(from, to);
            expect(result, isA<bool>());
          }
        }
      });
    });
  });
}

/// State machine for managing valid payment status transitions
class PaymentStateMachine {
  static bool canTransition(PaymentStatus from, PaymentStatus to) {
    const allowed = {
      PaymentStatus.initiated: {
        PaymentStatus.authorized,
        PaymentStatus.failed,
        PaymentStatus.timeout,
      },
      PaymentStatus.authorized: {
        PaymentStatus.captured,
        PaymentStatus.failed,
      },
      PaymentStatus.captured: {
        PaymentStatus.refundInitiated,
      },
      PaymentStatus.failed: <PaymentStatus>{},
      PaymentStatus.timeout: {
        PaymentStatus.initiated,
      },
      PaymentStatus.refundInitiated: {
        PaymentStatus.refundCompleted,
      },
      PaymentStatus.refundCompleted: <PaymentStatus>{},
    };

    return allowed[from]?.contains(to) ?? false;
  }
}
