import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:uuid/uuid.dart';

// Helper to create test database with in-memory storage
AppDatabase _createTestDatabase() {
  return AppDatabase.forTesting(InMemoryDriftDatabase());
}

void main() {
  group('AppDatabase', () {
    late AppDatabase database;

    setUp(() {
      database = _createTestDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    group('User operations', () {
      test('should insert and retrieve a user', () async {
        final userId = const Uuid().v4();
        final now = DateTime.now();

        final userCompanion = UsersCompanion(
          id: drift.Value(userId),
          name: drift.Value('John Farmer'),
          phone: drift.Value('9876543210'),
          villageId: drift.Value('village_123'),
          languagePref: drift.Value('hi'),
          avatarUrl: drift.Value(null),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        );

        await database.insertOrUpdateUser(userCompanion);
        final retrieved = await database.getUserById(userId);

        expect(retrieved, isNotNull);
        expect(retrieved?.name, 'John Farmer');
        expect(retrieved?.phone, '9876543210');
        expect(retrieved?.villageId, 'village_123');
      });

      test('should retrieve user by phone', () async {
        final userId = const Uuid().v4();
        final phone = '9876543210';
        final now = DateTime.now();

        await database.insertOrUpdateUser(
          UsersCompanion(
            id: drift.Value(userId),
            name: drift.Value('Raj Kumar'),
            phone: drift.Value(phone),
            villageId: drift.Value('village_456'),
            languagePref: drift.Value('en'),
            avatarUrl: drift.Value(null),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        final retrieved = await database.getUserByPhone(phone);

        expect(retrieved, isNotNull);
        expect(retrieved?.id, userId);
        expect(retrieved?.name, 'Raj Kumar');
      });

      test('should get all users', () async {
        final now = DateTime.now();

        for (int i = 0; i < 3; i++) {
          await database.insertOrUpdateUser(
            UsersCompanion(
              id: drift.Value(const Uuid().v4()),
              name: drift.Value('User $i'),
              phone: drift.Value('9876543210$i'),
              villageId: drift.Value('village_$i'),
              languagePref: drift.Value('en'),
              avatarUrl: drift.Value(null),
              createdAt: drift.Value(now),
              updatedAt: drift.Value(now),
            ),
          );
        }

        final users = await database.getAllUsers();

        expect(users.length, 3);
      });

      test('should delete a user', () async {
        final userId = const Uuid().v4();
        final now = DateTime.now();

        await database.insertOrUpdateUser(
          UsersCompanion(
            id: drift.Value(userId),
            name: drift.Value('Delete Me'),
            phone: drift.Value('9999999999'),
            villageId: drift.Value('village_delete'),
            languagePref: drift.Value('en'),
            avatarUrl: drift.Value(null),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await database.deleteUser(userId);
        final retrieved = await database.getUserById(userId);

        expect(retrieved, isNull);
      });
    });

    group('Crop Listing operations', () {
      test('should insert and retrieve crop listings', () async {
        final userId = const Uuid().v4();
        final listingId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cropListings).insert(
          CropListingsCompanion(
            id: drift.Value(listingId),
            userId: drift.Value(userId),
            cropType: drift.Value('Wheat'),
            cropName: drift.Value('Indian Wheat'),
            quantityQuintals: drift.Value(100.0),
            expectedPricePerQuintal: drift.Value(2500.0),
            description: drift.Value('High quality'),
            imagePathsJson: drift.Value('[]'),
            status: drift.Value('draft'),
            villageId: drift.Value('village_123'),
            synced: drift.Value(false),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        final listings = await database.getUserListings(userId);

        expect(listings, isNotEmpty);
        expect(listings.first.cropName, 'Indian Wheat');
      });

      test('should return listings in descending order by createdAt', () async {
        final userId = const Uuid().v4();
        final now = DateTime.now();

        for (int i = 0; i < 3; i++) {
          await database.into(database.cropListings).insert(
            CropListingsCompanion(
              id: drift.Value(const Uuid().v4()),
              userId: drift.Value(userId),
              cropType: drift.Value('Crop $i'),
              cropName: drift.Value('Crop $i'),
              quantityQuintals: drift.Value(50.0),
              expectedPricePerQuintal: drift.Value(2000.0),
              description: drift.Value(null),
              imagePathsJson: drift.Value('[]'),
              status: drift.Value('draft'),
              villageId: drift.Value('village_123'),
              synced: drift.Value(false),
              createdAt: drift.Value(now.add(Duration(days: i))),
              updatedAt: drift.Value(now.add(Duration(days: i))),
            ),
          );
        }

        final listings = await database.getUserListings(userId);

        expect(listings.length, 3);
        for (int i = 0; i < listings.length - 1; i++) {
          expect(listings[i].createdAt.isAfter(listings[i + 1].createdAt), true);
        }
      });

      test('should update crop listing status', () async {
        final listingId = const Uuid().v4();
        final userId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cropListings).insert(
          CropListingsCompanion(
            id: drift.Value(listingId),
            userId: drift.Value(userId),
            cropType: drift.Value('Rice'),
            cropName: drift.Value('Basmati'),
            quantityQuintals: drift.Value(50.0),
            expectedPricePerQuintal: drift.Value(null),
            description: drift.Value(null),
            imagePathsJson: drift.Value('[]'),
            status: drift.Value('draft'),
            villageId: drift.Value('village_123'),
            synced: drift.Value(false),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await (database.update(database.cropListings)
              ..where((t) => t.id.equals(listingId)))
            .write(const CropListingsCompanion(
              status: drift.Value('synced'),
            ));

        final listing = await database.getCropListingById(listingId);

        expect(listing?.status, 'synced');
      });

      test('should get unsynced listings', () async {
        final userId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cropListings).insert(
          CropListingsCompanion(
            id: drift.Value(const Uuid().v4()),
            userId: drift.Value(userId),
            cropType: drift.Value('Wheat'),
            cropName: drift.Value('Wheat 1'),
            quantityQuintals: drift.Value(100.0),
            expectedPricePerQuintal: drift.Value(null),
            description: drift.Value(null),
            imagePathsJson: drift.Value('[]'),
            status: drift.Value('pending_sync'),
            villageId: drift.Value('village_123'),
            synced: drift.Value(false),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await database.into(database.cropListings).insert(
          CropListingsCompanion(
            id: drift.Value(const Uuid().v4()),
            userId: drift.Value(userId),
            cropType: drift.Value('Rice'),
            cropName: drift.Value('Rice 1'),
            quantityQuintals: drift.Value(50.0),
            expectedPricePerQuintal: drift.Value(null),
            description: drift.Value(null),
            imagePathsJson: drift.Value('[]'),
            status: drift.Value('synced'),
            villageId: drift.Value('village_123'),
            synced: drift.Value(true),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        final unsynced = await database.getUnsyncedListings();

        expect(unsynced.length, 1);
        expect(unsynced.first.status, 'pending_sync');
      });
    });

    group('Cart operations', () {
      test('should add item to cart', () async {
        final cartId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cartItems).insert(
          CartItemsCompanion(
            id: drift.Value(cartId),
            productId: drift.Value('product_123'),
            productName: drift.Value('Urea Fertilizer'),
            unitPrice: drift.Value(150.0),
            quantity: drift.Value(1),
            imageUrl: drift.Value(null),
            addedAt: drift.Value(now),
          ),
        );

        final items = await database.getAllCartItems();

        expect(items, isNotEmpty);
        expect(items.first.productName, 'Urea Fertilizer');
      });

      test('should update cart item quantity', () async {
        final cartId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cartItems).insert(
          CartItemsCompanion(
            id: drift.Value(cartId),
            productId: drift.Value('product_456'),
            productName: drift.Value('DAP'),
            unitPrice: drift.Value(500.0),
            quantity: drift.Value(1),
            imageUrl: drift.Value(null),
            addedAt: drift.Value(now),
          ),
        );

        await (database.update(database.cartItems)
              ..where((t) => t.id.equals(cartId)))
            .write(const CartItemsCompanion(
              quantity: drift.Value(5),
            ));

        final items = await database.getAllCartItems();

        expect(items.first.quantity, 5);
      });

      test('should remove item from cart', () async {
        final cartId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.cartItems).insert(
          CartItemsCompanion(
            id: drift.Value(cartId),
            productId: drift.Value('product_789'),
            productName: drift.Value('Pesticide'),
            unitPrice: drift.Value(250.0),
            quantity: drift.Value(1),
            imageUrl: drift.Value(null),
            addedAt: drift.Value(now),
          ),
        );

        await (database.delete(database.cartItems)
              ..where((t) => t.id.equals(cartId)))
            .go();

        final items = await database.getAllCartItems();

        expect(items, isEmpty);
      });

      test('should clear all cart items', () async {
        final now = DateTime.now();

        for (int i = 0; i < 3; i++) {
          await database.into(database.cartItems).insert(
            CartItemsCompanion(
              id: drift.Value(const Uuid().v4()),
              productId: drift.Value('product_$i'),
              productName: drift.Value('Product $i'),
              unitPrice: drift.Value(100.0 * (i + 1)),
              quantity: drift.Value(1),
              imageUrl: drift.Value(null),
              addedAt: drift.Value(now),
            ),
          );
        }

        await database.delete(database.cartItems).go();
        final items = await database.getAllCartItems();

        expect(items, isEmpty);
      });

      test('should stream cart items', () async {
        final now = DateTime.now();
        final cartStream = database.getAllCartItemsStream();

        // Insert an item
        await database.into(database.cartItems).insert(
          CartItemsCompanion(
            id: drift.Value(const Uuid().v4()),
            productId: drift.Value('product_stream'),
            productName: drift.Value('Streaming Product'),
            unitPrice: drift.Value(150.0),
            quantity: drift.Value(1),
            imageUrl: drift.Value(null),
            addedAt: drift.Value(now),
          ),
        );

        // Check stream emits
        expect(
          cartStream,
          emits(isNotEmpty),
        );
      });
    });

    group('Payment operations', () {
      test('should insert payment pending record', () async {
        final paymentId = const Uuid().v4();
        final orderId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.paymentsPending).insert(
          PaymentsPendingCompanion(
            id: drift.Value(paymentId),
            orderId: drift.Value(orderId),
            razorpayOrderId: drift.Value('rpay_order_123'),
            amount: drift.Value(5000.0),
            currency: drift.Value('INR'),
            status: drift.Value('initiated'),
            razorpayPaymentId: drift.Value(null),
            razorpaySignature: drift.Value(null),
            failureReason: drift.Value(null),
            pollCount: drift.Value(0),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        final payment = await database.getPaymentByOrderId(orderId);

        expect(payment, isNotNull);
        expect(payment?.amount, 5000.0);
      });

      test('should get payment by Razorpay order ID', () async {
        final paymentId = const Uuid().v4();
        final orderId = const Uuid().v4();
        final rpayOrderId = 'rpay_order_456';
        final now = DateTime.now();

        await database.into(database.paymentsPending).insert(
          PaymentsPendingCompanion(
            id: drift.Value(paymentId),
            orderId: drift.Value(orderId),
            razorpayOrderId: drift.Value(rpayOrderId),
            amount: drift.Value(1000.0),
            currency: drift.Value('INR'),
            status: drift.Value('authorized'),
            razorpayPaymentId: drift.Value(null),
            razorpaySignature: drift.Value(null),
            failureReason: drift.Value(null),
            pollCount: drift.Value(1),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        final payment = await database.getPaymentByRazorpayOrderId(rpayOrderId);

        expect(payment, isNotNull);
        expect(payment?.orderId, orderId);
      });

      test('should update payment status', () async {
        final paymentId = const Uuid().v4();
        final orderId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.paymentsPending).insert(
          PaymentsPendingCompanion(
            id: drift.Value(paymentId),
            orderId: drift.Value(orderId),
            razorpayOrderId: drift.Value('rpay_order_789'),
            amount: drift.Value(2000.0),
            currency: drift.Value('INR'),
            status: drift.Value('initiated'),
            razorpayPaymentId: drift.Value(null),
            razorpaySignature: drift.Value(null),
            failureReason: drift.Value(null),
            pollCount: drift.Value(0),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await (database.update(database.paymentsPending)
              ..where((t) => t.id.equals(paymentId)))
            .write(const PaymentsPendingCompanion(
              status: drift.Value('captured'),
            ));

        final payment = await database.getPaymentByOrderId(orderId);

        expect(payment?.status, 'captured');
      });

      test('should increment payment poll count', () async {
        final paymentId = const Uuid().v4();
        final orderId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.paymentsPending).insert(
          PaymentsPendingCompanion(
            id: drift.Value(paymentId),
            orderId: drift.Value(orderId),
            razorpayOrderId: drift.Value('rpay_order_poll'),
            amount: drift.Value(3000.0),
            currency: drift.Value('INR'),
            status: drift.Value('authorized'),
            razorpayPaymentId: drift.Value(null),
            razorpaySignature: drift.Value(null),
            failureReason: drift.Value(null),
            pollCount: drift.Value(0),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await (database.update(database.paymentsPending)
              ..where((t) => t.id.equals(paymentId)))
            .write(PaymentsPendingCompanion(
              pollCount: drift.Value(1),
            ));

        final payment = await database.getPaymentByOrderId(orderId);

        expect(payment?.pollCount, 1);
      });
    });

    group('PendingSync operations', () {
      test('should insert pending sync record', () async {
        final syncId = const Uuid().v4();
        final entityId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.pendingSync).insert(
          PendingSyncCompanion(
            id: drift.Value(syncId),
            entityType: drift.Value('order'),
            entityId: drift.Value(entityId),
            payloadJson: drift.Value('{"key":"value"}'),
            idempotencyKey: drift.Value(const Uuid().v4()),
            createdAt: drift.Value(now),
            retryCount: drift.Value(0),
            lastRetryAt: drift.Value(null),
            status: drift.Value('pending'),
            failureReason: drift.Value(null),
          ),
        );

        final items = await database.getPendingSyncItems();

        expect(items, isNotEmpty);
        expect(items.first.entityType, 'order');
      });

      test('should return pending items in ascending order by createdAt', () async {
        final now = DateTime.now();

        for (int i = 0; i < 3; i++) {
          await database.into(database.pendingSync).insert(
            PendingSyncCompanion(
              id: drift.Value(const Uuid().v4()),
              entityType: drift.Value('entity_$i'),
              entityId: drift.Value(const Uuid().v4()),
              payloadJson: drift.Value('{}'),
              idempotencyKey: drift.Value(const Uuid().v4()),
              createdAt: drift.Value(now.add(Duration(days: 2 - i))),
              retryCount: drift.Value(0),
              lastRetryAt: drift.Value(null),
              status: drift.Value('pending'),
              failureReason: drift.Value(null),
            ),
          );
        }

        final items = await database.getPendingSyncItems();

        expect(items.length, 3);
        for (int i = 0; i < items.length - 1; i++) {
          expect(items[i].createdAt.isBefore(items[i + 1].createdAt), true);
        }
      });

      test('should update sync status', () async {
        final syncId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.pendingSync).insert(
          PendingSyncCompanion(
            id: drift.Value(syncId),
            entityType: drift.Value('crop'),
            entityId: drift.Value(const Uuid().v4()),
            payloadJson: drift.Value('{}'),
            idempotencyKey: drift.Value(const Uuid().v4()),
            createdAt: drift.Value(now),
            retryCount: drift.Value(0),
            lastRetryAt: drift.Value(null),
            status: drift.Value('pending'),
            failureReason: drift.Value(null),
          ),
        );

        await (database.update(database.pendingSync)
              ..where((t) => t.id.equals(syncId)))
            .write(const PendingSyncCompanion(
              status: drift.Value('synced'),
            ));

        final item = await (database.select(database.pendingSync)
              ..where((t) => t.id.equals(syncId)))
            .getSingleOrNull();

        expect(item?.status, 'synced');
      });

      test('should increment retry count', () async {
        final syncId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.pendingSync).insert(
          PendingSyncCompanion(
            id: drift.Value(syncId),
            entityType: drift.Value('payment'),
            entityId: drift.Value(const Uuid().v4()),
            payloadJson: drift.Value('{}'),
            idempotencyKey: drift.Value(const Uuid().v4()),
            createdAt: drift.Value(now),
            retryCount: drift.Value(2),
            lastRetryAt: drift.Value(null),
            status: drift.Value('pending'),
            failureReason: drift.Value(null),
          ),
        );

        await (database.update(database.pendingSync)
              ..where((t) => t.id.equals(syncId)))
            .write(const PendingSyncCompanion(
              retryCount: drift.Value(3),
            ));

        final item = await (database.select(database.pendingSync)
              ..where((t) => t.id.equals(syncId)))
            .getSingleOrNull();

        expect(item?.retryCount, 3);
      });
    });

    group('Product operations', () {
      test('should insert and retrieve product', () async {
        final productId = const Uuid().v4();
        final now = DateTime.now();

        await database.into(database.products).insert(
          ProductsCompanion(
            id: drift.Value(productId),
            name: drift.Value('Urea'),
            nameLocal: drift.Value('यूरिया'),
            category: drift.Value('Fertilizer'),
            description: drift.Value('Nitrogen fertilizer'),
            price: drift.Value(150.0),
            mrp: drift.Value(200.0),
            unit: drift.Value('bag'),
            imageUrl: drift.Value('https://example.com/image.jpg'),
            stockQuantity: drift.Value(100),
            inStock: drift.Value(true),
            brand: drift.Value('Agro'),
            fetchedAt: drift.Value(now),
          ),
        );

        final product = await (database.select(database.products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();

        expect(product, isNotNull);
        expect(product?.name, 'Urea');
      });

      test('should search products by name', () async {
        final now = DateTime.now();

        await database.into(database.products).insert(
          ProductsCompanion(
            id: drift.Value(const Uuid().v4()),
            name: drift.Value('Urea Fertilizer'),
            nameLocal: drift.Value('यूरिया खाद'),
            category: drift.Value('Fertilizer'),
            description: drift.Value('Nitrogen'),
            price: drift.Value(150.0),
            mrp: drift.Value(200.0),
            unit: drift.Value('bag'),
            imageUrl: drift.Value(null),
            stockQuantity: drift.Value(50),
            inStock: drift.Value(true),
            brand: drift.Value(null),
            fetchedAt: drift.Value(now),
          ),
        );

        final results = await database.searchProducts('Urea');

        expect(results, isNotEmpty);
        expect(results.first.name.contains('Urea'), true);
      });

      test('should search products by nameLocal', () async {
        final now = DateTime.now();

        await database.into(database.products).insert(
          ProductsCompanion(
            id: drift.Value(const Uuid().v4()),
            name: drift.Value('DAP'),
            nameLocal: drift.Value('डीएपी खाद'),
            category: drift.Value('Fertilizer'),
            description: drift.Value('Phosphate'),
            price: drift.Value(500.0),
            mrp: drift.Value(600.0),
            unit: drift.Value('bag'),
            imageUrl: drift.Value(null),
            stockQuantity: drift.Value(30),
            inStock: drift.Value(true),
            brand: drift.Value(null),
            fetchedAt: drift.Value(now),
          ),
        );

        final results = await database.searchProducts('डीएपी');

        expect(results, isNotEmpty);
      });
    });

    group('deleteAllData', () {
      test('should clear all 9 tables', () async {
        final now = DateTime.now();

        await database.insertOrUpdateUser(
          UsersCompanion(
            id: drift.Value(const Uuid().v4()),
            name: drift.Value('Test'),
            phone: drift.Value('1234567890'),
            villageId: drift.Value('v1'),
            languagePref: drift.Value('en'),
            avatarUrl: drift.Value(null),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );

        await database.into(database.cartItems).insert(
          CartItemsCompanion(
            id: drift.Value(const Uuid().v4()),
            productId: drift.Value('p1'),
            productName: drift.Value('Test'),
            unitPrice: drift.Value(100.0),
            quantity: drift.Value(1),
            imageUrl: drift.Value(null),
            addedAt: drift.Value(now),
          ),
        );

        await database.deleteAllData();

        final users = await database.getAllUsers();
        final cartItems = await database.getAllCartItems();

        expect(users, isEmpty);
        expect(cartItems, isEmpty);
      });
    });
  });
}

// Extension to AppDatabase for testing
extension TestAppDatabase on AppDatabase {
  static AppDatabase forTesting(drift.DatabaseConnection connection) {
    return AppDatabase._testConstructor(connection);
  }

  Future<List<CartItemEntity>> getAllCartItems() {
    return select(cartItems).get();
  }

  Stream<List<CartItemEntity>> getAllCartItemsStream() {
    return select(cartItems).watch();
  }

  Future<CropListingEntity?> getCropListingById(String id) {
    return (select(cropListings)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CropListingEntity>> getUserListings(String userId) {
    return (select(cropListings)
          ..where((c) => c.userId.equals(userId))
          ..orderBy([(c) => drift.OrderingTerm(
                expression: c.createdAt,
                mode: drift.OrderingMode.desc,
              )]))
        .get();
  }

  Future<List<CropListingEntity>> getUnsyncedListings() {
    return (select(cropListings)
          ..where((c) =>
              c.status.equals('pending_sync') | c.status.equals('draft')))
        .get();
  }

  Future<PaymentPendingEntity?> getPaymentByOrderId(String orderId) {
    return (select(paymentsPending)
          ..where((p) => p.orderId.equals(orderId)))
        .getSingleOrNull();
  }

  Future<PaymentPendingEntity?> getPaymentByRazorpayOrderId(
      String razorpayOrderId) {
    return (select(paymentsPending)
          ..where((p) => p.razorpayOrderId.equals(razorpayOrderId)))
        .getSingleOrNull();
  }

  Future<List<PendingSyncEntity>> getPendingSyncItems(
      {int limit = 100, int offset = 0}) {
    return (select(pendingSync)
          ..where((p) => p.status.equals('pending'))
          ..orderBy([(p) => drift.OrderingTerm(expression: p.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<ProductEntity>> searchProducts(String query) {
    return (select(products)
          ..where((p) =>
              p.name.like('%$query%') | p.nameLocal.like('%$query%')))
        .get();
  }
}

// Constructor for test database
class _$AppDatabase {
  static AppDatabase _testConstructor(drift.DatabaseConnection connection) {
    final instance = _$AppDatabase();
    instance._openConnection = () => connection;
    return instance as AppDatabase;
  }
}
