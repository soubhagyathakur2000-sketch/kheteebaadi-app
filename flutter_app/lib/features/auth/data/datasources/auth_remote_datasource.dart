import 'package:dio/dio.dart';
import 'package:kheteebaadi/core/constants/api_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/utils/failure.dart';
import 'package:kheteebaadi/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> requestOtp(String phone);
  Future<UserModel> verifyOtp(String phone, String otp);
  Future<UserModel> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<void> requestOtp(String phone) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.requestOtpEndpoint,
        data: {'phone': phone},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'Failed to request OTP',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyOtpEndpoint,
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'OTP verification failed',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid user data in response');
      }

      return UserModel.fromJson(user);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserModel> refreshToken(String refreshTokenValue) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshTokenValue},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(
          message: 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid response format');
      }

      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw ServerFailure(message: 'Invalid user data in response');
      }

      return UserModel.fromJson(user);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutFailure(message: 'Request timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail'] ?? error.response?.data?['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthFailure(message: message);
        }
        return ServerFailure(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'Network error');
      default:
        return ServerFailure(message: error.message ?? 'Unknown error');
    }
  }
}
