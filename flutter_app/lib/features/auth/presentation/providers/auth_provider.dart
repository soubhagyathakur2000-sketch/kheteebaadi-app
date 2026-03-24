import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/core/di/injection.dart';
import 'package:kheteebaadi/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:kheteebaadi/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kheteebaadi/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kheteebaadi/features/auth/domain/entities/user_entity.dart';
import 'package:kheteebaadi/features/auth/domain/repositories/auth_repository.dart';
import 'package:kheteebaadi/features/auth/domain/usecases/login_usecase.dart';

// Repository providers
final authRemoteDataSourceProvider = Provider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});

final authLocalDataSourceProvider = FutureProvider((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final authBox = await ref.watch(authBoxProvider.future);
  return AuthLocalDataSourceImpl(
    secureStorage: secureStorage,
    box: authBox,
  );
});

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final remoteDataSource = await ref.watch(authRemoteDataSourceProvider.future);
  final localDataSource = await ref.watch(authLocalDataSourceProvider.future);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

final loginUseCaseProvider = FutureProvider((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return LoginUseCase(repository: repository);
});

// Auth State
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isOtpSent;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isOtpSent = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isOtpSent,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthNotifier({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(AuthState());

  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true);
    final result = await _loginUseCase.hasValidSession();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: failure.message,
      ),
      (hasSession) {
        if (hasSession) {
          _loadCurrentUser();
        } else {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
          );
        }
      },
    );
  }

  Future<void> _loadCurrentUser() async {
    final result = await _loginUseCase.getCurrentUser();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: user != null,
      ),
    );
  }

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _loginUseCase.requestOtp(phone);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        isOtpSent: false,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        isOtpSent: true,
        error: null,
      ),
    );
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _loginUseCase.verifyOtp(phone, otp);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        isAuthenticated: false,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        error: null,
        isOtpSent: false,
      ),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(
      isLoading: false,
      user: null,
      isAuthenticated: false,
      isOtpSent: false,
      error: null,
    );
  }

  void resetState() {
    state = AuthState();
  }
}

// Auth Provider
final authProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) async {
  final loginUseCase = await ref.watch(loginUseCaseProvider.future);
  final notifier = AuthNotifier(loginUseCase: loginUseCase);
  await notifier.checkSession();
  return notifier;
});
