import 'package:kheteebaadi/core/utils/either.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:kheteebaadi/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kheteebaadi/features/auth/domain/entities/user_entity.dart';
import 'package:kheteebaadi/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, void>> requestOtp(String phone) async {
    try {
      await _remoteDataSource.requestOtp(phone);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp) async {
    try {
      final user = await _remoteDataSource.verifyOtp(phone, otp);
      await _localDataSource.saveUser(user);
      await _localDataSource.saveTokens(user.token, user.refreshToken);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _localDataSource.getUser();
      if (user != null) {
        return Right(user);
      }
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to get user: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _localDataSource.clearAuth();
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to logout: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshToken() async {
    try {
      final refreshTokenValue = await _localDataSource.getRefreshToken();
      if (refreshTokenValue == null) {
        return Left(
          AuthFailure(message: 'No refresh token available'),
        );
      }

      final user = await _remoteDataSource.refreshToken(refreshTokenValue);
      await _localDataSource.saveUser(user);
      await _localDataSource.saveTokens(user.token, user.refreshToken);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Unexpected error: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidSession() async {
    try {
      final hasSession = await _localDataSource.hasValidSession();
      return Right(hasSession);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to check session: ${e.toString()}'),
      );
    }
  }
}
