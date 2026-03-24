import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kheteebaadi/core/constants/app_constants.dart';
import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/network/connectivity_service.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/core/services/image_compression_service.dart';
import 'package:kheteebaadi/core/services/camera_service.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Database provider
final appDatabaseProvider = FutureProvider((ref) async {
  return AppDatabase();
});

// Network providers
final connectivityProvider = Provider((ref) {
  return Connectivity();
});

final networkInfoProvider = Provider((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfoImpl(connectivity: connectivity);
});

final connectivityServiceProvider = Provider((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return ConnectivityService(networkInfo: networkInfo);
});

// API Client provider
final apiClientProvider = Provider((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return ApiClient(networkInfo: networkInfo);
});

// Secure Storage provider
final secureStorageProvider = Provider((ref) {
  return const FlutterSecureStorage();
});

// SharedPreferences provider
final sharedPreferencesProvider = FutureProvider((ref) async {
  return SharedPreferences.getInstance();
});

// Hive boxes providers
final authBoxProvider = FutureProvider((ref) async {
  return Hive.openBox(AppConstants.authBoxName);
});

final userBoxProvider = FutureProvider((ref) async {
  return Hive.openBox(AppConstants.userBoxName);
});

final settingsBoxProvider = FutureProvider((ref) async {
  return Hive.openBox(AppConstants.settingsBoxName);
});

// Connectivity Stream provider
final connectivityStreamProvider =
    StreamProvider((ref) async* {
  final connectivityService = ref.watch(connectivityServiceProvider);
  yield* connectivityService.connectionStream;
});

// Connection Status provider
final connectionStatusProvider = StreamProvider((ref) async* {
  final connectivityService = ref.watch(connectivityServiceProvider);
  while (true) {
    final status = await connectivityService.checkConnectionStatus();
    yield status;
    await Future.delayed(const Duration(seconds: 5));
  }
});

// Phase 4 - Core Services
final imageCompressionServiceProvider = Provider((ref) {
  return ImageCompressionService();
});

final cameraServiceProvider = Provider((ref) {
  final compressionService = ref.watch(imageCompressionServiceProvider);
  return CameraService(compressionService: compressionService);
});
