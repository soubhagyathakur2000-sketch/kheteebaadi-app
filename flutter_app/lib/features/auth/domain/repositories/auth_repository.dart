import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> requestOtp(String phone);
  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp);
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> refreshToken();
  Future<Either<Failure, bool>> hasValidSession();
}
