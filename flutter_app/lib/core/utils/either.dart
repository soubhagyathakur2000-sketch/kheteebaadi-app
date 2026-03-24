import 'package:kheteebaadi/core/utils/failure.dart';

sealed class Either<L, R> {
  T fold<T>(T Function(L) onLeft, T Function(R) onRight);
  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R) f);
  Either<L, R2> map<R2>(R2 Function(R) f);
  Either<L2, R> mapLeft<L2>(L2 Function(L) f);
  bool isLeft();
  bool isRight();
}

class Left<L, R> implements Either<L, R> {
  final L value;

  Left(this.value);

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onLeft(value);

  @override
  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R) f) => Left<L, R2>(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R) f) => Left<L, R2>(value);

  @override
  Either<L2, R> mapLeft<L2>(L2 Function(L) f) => Left<L2, R>(f(value));

  @override
  bool isLeft() => true;

  @override
  bool isRight() => false;

  @override
  String toString() => 'Left($value)';
}

class Right<L, R> implements Either<L, R> {
  final R value;

  Right(this.value);

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onRight(value);

  @override
  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R) f) => f(value);

  @override
  Either<L, R2> map<R2>(R2 Function(R) f) => Right<L, R2>(f(value));

  @override
  Either<L2, R> mapLeft<L2>(L2 Function(L) f) => Right<L2, R>(value);

  @override
  bool isLeft() => false;

  @override
  bool isRight() => true;

  @override
  String toString() => 'Right($value)';
}

extension EitherExtension<L, R> on Either<L, R> {
  R? getOrNull() {
    if (this is Right<L, R>) {
      return (this as Right<L, R>).value;
    }
    return null;
  }

  L? getLeftOrNull() {
    if (this is Left<L, R>) {
      return (this as Left<L, R>).value;
    }
    return null;
  }

  R getOrElse(R Function() defaultValue) {
    return fold((_) => defaultValue(), (r) => r);
  }

  Future<Either<L, R2>> flatMapAsync<R2>(
      Future<Either<L, R2>> Function(R) f) async {
    if (isLeft()) {
      return Left<L, R2>((this as Left<L, R>).value);
    }
    return f((this as Right<L, R>).value);
  }
}
