import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/auth/domain/entities/user_entity.dart';
import 'package:kheteebaadi/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase({required AuthRepository repository}) : _repository = repository;

  Future<Either<Failure, void>> requestOtp(String phone) {
    return _repository.requestOtp(phone);
  }

  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp) {
    return _repository.verifyOtp(phone, otp);
  }

  Future<Either<Failure, UserEntity?>> getCurrentUser() {
    return _repository.getCurrentUser();
  }

  Future<Either<Failure, bool>> hasValidSession() {
    return _repository.hasValidSession();
  }
}
