import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'IN'),
    Locale('hi', 'IN'),
    Locale('mr', 'IN'),
  ];

  static const Locale defaultLocale = Locale('en', 'IN');

  // Sync configuration
  static const int syncBatchSize = 50;
  static const int maxRetryCount = 5;
  static const int initialBackoffMs = 1000;
  static const double backoffMultiplier = 2.0;

  // App info
  static const String appName = 'Kheteebaadi';
  static const String appVersion = '1.0.0';

  // OTP configuration
  static const int otpLength = 6;
  static const int otpResendTimeoutSeconds = 60;

  // Cache sizes
  static const int maxCacheSize = 1000;
  static const int cacheCleanupThreshold = 900;

  // Pagination
  static const int defaultPageSize = 20;

  // Hive box names
  static const String authBoxName = 'auth_box';
  static const String userBoxName = 'user_box';
  static const String settingsBoxName = 'settings_box';

  // Local database filename
  static const String dbFileName = 'kheteebaadi.db';

  // Phase 4 - Image compression
  static const int maxImageWidth = 800;
  static const int imageQuality = 70;
  static const int maxListingImages = 3;
  static const int maxImageSizeKb = 150;

  // Phase 4 - Payment
  // Razorpay key switches via AppConfig based on --dart-define=ENV
  // Production: pass --dart-define=RAZORPAY_KEY=rzp_live_xxx when building
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: 'rzp_test_XXXXXXXXXXXXXXX',
  );
  static const int paymentPollIntervalSeconds = 30;
  static const int paymentStuckThresholdMinutes = 5;
  static const int paymentMaxPollAttempts = 10;

  // Phase 4 - Voice search
  static const double voiceSilenceTimeout = 1.5; // seconds
  static const String defaultSpeechLocale = 'hi_IN';

  // Phase 4 - Weather
  static const int weatherCacheTtlMinutes = 30;

  // Hive box names (Phase 4)
  static const String cartBoxName = 'cart_box';
  static const String paymentBoxName = 'payment_box';
}
