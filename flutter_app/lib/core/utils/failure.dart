sealed class Failure {
  final String message;
  final String? code;

  Failure({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class ServerFailure extends Failure {
  final int? statusCode;

  ServerFailure({
    required String message,
    this.statusCode,
    String? code,
  }) : super(message: message, code: code ?? 'SERVER_ERROR');

  @override
  String toString() =>
      'ServerFailure(message: $message, statusCode: $statusCode, code: $code)';
}

class CacheFailure extends Failure {
  CacheFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'CACHE_ERROR');

  @override
  String toString() => 'CacheFailure(message: $message, code: $code)';
}

class NetworkFailure extends Failure {
  NetworkFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'NETWORK_ERROR');

  @override
  String toString() => 'NetworkFailure(message: $message, code: $code)';
}

class AuthFailure extends Failure {
  AuthFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'AUTH_ERROR');

  @override
  String toString() => 'AuthFailure(message: $message, code: $code)';
}

class SyncFailure extends Failure {
  final int? retryCount;

  SyncFailure({
    required String message,
    this.retryCount,
    String? code,
  }) : super(message: message, code: code ?? 'SYNC_ERROR');

  @override
  String toString() =>
      'SyncFailure(message: $message, retryCount: $retryCount, code: $code)';
}

class ValidationFailure extends Failure {
  ValidationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'VALIDATION_ERROR');

  @override
  String toString() => 'ValidationFailure(message: $message, code: $code)';
}

class TimeoutFailure extends Failure {
  TimeoutFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code ?? 'TIMEOUT_ERROR');

  @override
  String toString() => 'TimeoutFailure(message: $message, code: $code)';
}
