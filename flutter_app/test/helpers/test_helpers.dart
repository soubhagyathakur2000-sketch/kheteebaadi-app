import 'package:kheteebaadi/core/network/api_client.dart';
import 'package:kheteebaadi/core/network/network_info.dart';
import 'package:kheteebaadi/features/crop_listing/data/models/crop_listing_model.dart';
import 'package:kheteebaadi/features/crop_listing/domain/entities/crop_listing.dart';
import 'package:kheteebaadi/features/payment/data/models/payment_model.dart';
import 'package:kheteebaadi/features/payment/domain/entities/payment.dart';
import 'package:kheteebaadi/features/store/data/models/product_model.dart';
import 'package:uuid/uuid.dart';

/// Mock ApiClient for testing
class MockApiClient implements ApiClient {
  bool shouldFail = false;
  int? failureStatusCode;
  dynamic failureResponse;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('API request failed');
    }
    return {'success': true};
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('API request failed');
    }
    return {'success': true};
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('API request failed');
    }
    return {'success': true};
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('API request failed');
    }
    return {'success': true};
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('API request failed');
    }
    return {'success': true};
  }

  @override
  Future<dynamic> upload(
    String path,
    String filePath, {
    Map<String, String>? headers,
  }) async {
    if (shouldFail) {
      throw Exception('Upload failed');
    }
    return {'success': true};
  }
}

/// Mock NetworkInfo for testing
class MockNetworkInfo implements NetworkInfo {
  bool _isConnected = true;

  void setConnected(bool connected) {
    _isConnected = connected;
  }

  @override
  Future<bool> isConnected() async => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged =>
      Stream.value(_isConnected).asBroadcastStream();
}

/// Factory for creating test CropListingModel instances
class TestCropListingFactory {
  static CropListingModel createTestCropListing({
    String? id,
    String? userId,
    String? cropType,
    String? cropName,
    double? quantityQuintals,
    double? expectedPricePerQuintal,
    String? description,
    List<String>? imagePaths,
    CropListingStatus? status,
    String? villageId,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropListingModel(
      id: id ?? const Uuid().v4(),
      userId: userId ?? 'user_123',
      cropType: cropType ?? 'Wheat',
      cropName: cropName ?? 'Wheat',
      quantityQuintals: quantityQuintals ?? 100.0,
      expectedPricePerQuintal: expectedPricePerQuintal ?? 2500.0,
      description: description ?? 'Test crop listing',
      imagePaths: imagePaths ?? ['path/to/image1.jpg'],
      status: status ?? CropListingStatus.draft,
      villageId: villageId ?? 'village_123',
      synced: synced ?? false,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Factory for creating test ProductModel instances
class TestProductFactory {
  static ProductModel createTestProduct({
    int? id,
    String? name,
    String? nameLocal,
    String? category,
    String? description,
    double? price,
    double? mrp,
    String? unit,
    String? imageUrl,
    int? stockQuantity,
    bool? inStock,
    String? brand,
  }) {
    return ProductModel(
      id: id ?? 1,
      name: name ?? 'Test Product',
      nameLocal: nameLocal ?? 'परीक्षण उत्पाद',
      category: category ?? 'Fertilizer',
      description: description ?? 'Test description',
      price: price ?? 150.0,
      mrp: mrp ?? 200.0,
      unit: unit ?? 'bag',
      imageUrl: imageUrl ?? 'https://example.com/image.jpg',
      stockQuantity: stockQuantity ?? 50,
      inStock: inStock ?? true,
      brand: brand ?? 'TestBrand',
    );
  }
}

/// Factory for creating test PaymentModel instances
class TestPaymentFactory {
  static PaymentModel createTestPayment({
    int? id,
    String? orderId,
    String? razorpayOrderId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? razorpayPaymentId,
    String? razorpaySignature,
    String? failureReason,
    int? pollCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? 1,
      orderId: orderId ?? const Uuid().v4(),
      razorpayOrderId: razorpayOrderId,
      amount: amount ?? 5000.0,
      currency: currency ?? 'INR',
      status: status ?? PaymentStatus.initiated,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      failureReason: failureReason,
      pollCount: pollCount ?? 0,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
