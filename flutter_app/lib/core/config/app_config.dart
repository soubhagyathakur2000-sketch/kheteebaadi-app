/// Application configuration that switches between environments.
///
/// Usage in api_constants.dart:
///   static String get baseUrl => AppConfig.apiBaseUrl;
///
/// To switch environments, change [_currentEnv] or pass
/// --dart-define=ENV=production when building:
///   flutter build apk --dart-define=ENV=production
class AppConfig {
  AppConfig._();

  static const String _currentEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static bool get isProduction => _currentEnv == 'production';
  static bool get isDevelopment => _currentEnv == 'development';

  /// API base URL — switches based on build environment
  static String get apiBaseUrl {
    switch (_currentEnv) {
      case 'development':
        // Android emulator uses 10.0.2.2 to reach host machine's localhost
        return 'http://10.0.2.2:8000';
      case 'staging':
        return 'https://staging-api.kheteebaadi.com';
      case 'production':
      default:
        return 'https://api.kheteebaadi.com';
    }
  }

  /// Razorpay key — test key for dev, live key for production
  static String get razorpayKey {
    if (isProduction) {
      return const String.fromEnvironment(
        'RAZORPAY_KEY',
        defaultValue: 'rzp_live_XXXXXXXXXXXXXXX',
      );
    }
    return 'rzp_test_XXXXXXXXXXXXXXX';
  }

  /// S3 upload bucket
  static String get s3Bucket {
    return isProduction ? 'kheteebaadi-prod' : 'kheteebaadi-dev';
  }

  /// CloudFront CDN URL for images
  static String get cdnBaseUrl {
    return isProduction
        ? 'https://cdn.kheteebaadi.in'
        : 'http://10.0.2.2:8000/uploads';
  }

  /// Current environment name (for logging)
  static String get environmentName => _currentEnv;
}
