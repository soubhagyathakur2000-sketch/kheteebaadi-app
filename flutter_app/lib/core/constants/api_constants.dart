import 'package:kheteebaadi/core/config/app_config.dart';

class ApiConstants {
  ApiConstants._();

  // ── Base URL (environment-aware via AppConfig) ────────────
  // Switches automatically based on --dart-define=ENV=production|development|staging
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String apiVersion = '/api/v1';
  static String get fullBaseUrl => '$baseUrl$apiVersion';

  // ── Auth endpoints (matched to FastAPI /auth router) ─────
  static const String requestOtpEndpoint = '/auth/otp/request';
  static const String verifyOtpEndpoint = '/auth/otp/verify';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';

  // ── Mandi endpoints (matched to FastAPI /mandi router) ───
  static const String mandiPricesEndpoint = '/mandi/prices';
  static const String searchCropsEndpoint = '/mandi/search';
  static const String mandiDetailEndpoint = '/mandi/prices'; // append /{mandi_id}
  static const String mandiNearbyEndpoint = '/mandi/nearby';

  // ── Order endpoints (matched to FastAPI /orders router) ──
  static const String createOrderEndpoint = '/orders'; // POST
  static const String getOrdersEndpoint = '/orders'; // GET
  static const String getOrderDetailEndpoint = '/orders'; // append /{order_id}
  static const String cancelOrderEndpoint = '/orders'; // append /{order_id}/cancel
  static const String updateOrderStatusEndpoint = '/orders'; // append /{order_id}/status

  // ── Sync endpoints ───────────────────────────────────────
  static const String syncBatchEndpoint = '/sync/batch';

  // ── User endpoints (matched to FastAPI /users router) ────
  static const String userProfileEndpoint = '/users/me';
  static const String userStatsEndpoint = '/users/me/stats';

  // ── Village endpoints (matched to FastAPI /villages router)
  static const String villagesEndpoint = '/villages';
  static const String villageDetailEndpoint = '/villages'; // append /{village_id}
  static const String villagesNearbyEndpoint = '/villages/nearby';

  // ── Crop Listing endpoints (placeholder - backend TBD) ───
  static const String createListingEndpoint = '/listings/create';
  static const String getListingsEndpoint = '/listings';
  static const String uploadListingImageEndpoint = '/listings/upload';

  // ── Store endpoints (placeholder - backend TBD) ──────────
  static const String storeProductsEndpoint = '/store/products';
  static const String storeProductDetailEndpoint = '/store/products';
  static const String storeCategoriesEndpoint = '/store/categories';

  // ── Payment endpoints (placeholder - backend TBD) ────────
  static const String createPaymentEndpoint = '/payments/create';
  static const String verifyPaymentEndpoint = '/payments/verify';
  static const String paymentStatusEndpoint = '/payments/status';
  static const String webhookRazorpayEndpoint = '/webhooks/razorpay';

  // ── Weather endpoint (placeholder - backend TBD) ─────────
  static const String weatherEndpoint = '/weather';

  // ── Health check ─────────────────────────────────────────
  static const String healthEndpoint = '/health';

  // ── Timeouts in seconds ──────────────────────────────────
  static const int connectTimeout = 15;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // ── Cache TTLs in minutes ────────────────────────────────
  static const int mandiPricesCacheTtl = 15;
  static const int ordersCacheTtl = 5;
  static const int cropsCacheTtl = 60;

  // ── Pagination defaults ──────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
