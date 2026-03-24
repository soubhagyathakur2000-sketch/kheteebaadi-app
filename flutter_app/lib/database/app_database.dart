import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('UserEntity')
class Users extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get name => text()();
  TextColumn get phone => text().unique()();
  TextColumn get villageId => text()();
  TextColumn get languagePref => text().withDefault(const Constant('en'))();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('MandiPriceEntity')
class MandiPrices extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get cropName => text()();
  TextColumn get cropNameLocal => text().nullable()();
  RealColumn get pricePerQuintal => real()();
  TextColumn get mandiName => text()();
  TextColumn get mandiId => text()();
  TextColumn get regionId => text()();
  TextColumn get unit => text().withDefault(const Constant('quintal'))();
  RealColumn get priceChange => real().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  BoolColumn get isCached => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {cropName, mandiId, regionId}
      ];
}

@DataClassName('OrderEntity')
class Orders extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get userId => text()();
  TextColumn get itemsJson => text()();
  RealColumn get totalAmount => real()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending, confirmed, shipped, delivered
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DataClassName('PendingSyncEntity')
class PendingSync extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get entityType => text()(); // user, order, etc
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastRetryAt => dateTime().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending, synced, failed
  TextColumn get failureReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('VillageEntity')
class Villages extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get name => text()();
  TextColumn get district => text()();
  TextColumn get state => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
}

@DataClassName('CropListingEntity')
class CropListings extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get userId => text()();
  TextColumn get cropType => text()();
  TextColumn get cropName => text()();
  RealColumn get quantityQuintals => real()();
  RealColumn get expectedPricePerQuintal => real().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get imagePathsJson => text().withDefault(const Constant('[]'))();
  TextColumn get status => text().withDefault(const Constant('draft'))(); // draft, pending_sync, synced, sold
  TextColumn get villageId => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('ProductEntity')
class Products extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get name => text()();
  TextColumn get nameLocal => text().nullable()();
  TextColumn get category => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  RealColumn get mrp => real().nullable()();
  TextColumn get unit => text().withDefault(const Constant('piece'))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  BoolColumn get inStock => boolean().withDefault(const Constant(true))();
  TextColumn get brand => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
}

@DataClassName('CartItemEntity')
class CartItems extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
}

@DataClassName('PaymentPendingEntity')
class PaymentsPending extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get orderId => text()();
  TextColumn get razorpayOrderId => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get status => text().withDefault(const Constant('initiated'))(); // initiated, authorized, captured, failed, timeout
  TextColumn get razorpayPaymentId => text().nullable()();
  TextColumn get razorpaySignature => text().nullable()();
  TextColumn get failureReason => text().nullable()();
  IntColumn get pollCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Users, MandiPrices, Orders, PendingSync, Villages, CropListings, Products, CartItems, PaymentsPending])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  Future<void> deleteAllData() async {
    await delete(users).go();
    await delete(mandiPrices).go();
    await delete(orders).go();
    await delete(pendingSync).go();
    await delete(villages).go();
    await delete(cropListings).go();
    await delete(products).go();
    await delete(cartItems).go();
    await delete(paymentsPending).go();
  }

  // User DAOs
  Future<UserEntity?> getUserById(String id) async {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Future<UserEntity?> getUserByPhone(String phone) async {
    return (select(users)..where((u) => u.phone.equals(phone)))
        .getSingleOrNull();
  }

  Future<List<UserEntity>> getAllUsers() async {
    return select(users).get();
  }

  Future<void> insertOrUpdateUser(UsersCompanion user) async {
    return into(users).insertOnConflictUpdate(user);
  }

  Future<void> deleteUser(String id) async {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }

  // Mandi Price DAOs
  Future<MandiPriceEntity?> getMandiPriceById(String id) async {
    return (select(mandiPrices)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<MandiPriceEntity>> getMandiPricesByRegion(String regionId,
      {int limit = 20, int offset = 0}) async {
    return (select(mandiPrices)
          ..where((p) => p.regionId.equals(regionId))
          ..orderBy([(p) => OrderingTerm(expression: p.fetchedAt, mode: OrderingMode.desc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<MandiPriceEntity>> searchMandiPrices(String cropQuery,
      {int limit = 20}) async {
    return (select(mandiPrices)
          ..where((p) =>
              p.cropName.like('%$cropQuery%') |
              p.cropNameLocal.like('%$cropQuery%'))
          ..orderBy([(p) => OrderingTerm(expression: p.fetchedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  Future<List<MandiPriceEntity>> getCachedMandiPrices(
    String regionId,
    Duration maxAge,
  ) async {
    final cutoffTime = DateTime.now().subtract(maxAge);
    return (select(mandiPrices)
          ..where((p) =>
              p.regionId.equals(regionId) & p.fetchedAt.isBiggerThanValue(cutoffTime))
          ..orderBy([(p) => OrderingTerm(expression: p.fetchedAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> insertOrUpdateMandiPrice(MandiPricesCompanion price) async {
    return into(mandiPrices).insertOnConflictUpdate(price);
  }

  Future<void> insertOrUpdateMandiPrices(
      List<MandiPricesCompanion> prices) async {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(mandiPrices, prices);
    });
  }

  Future<void> deleteMandiPrice(String id) async {
    return (delete(mandiPrices)..where((p) => p.id.equals(id))).go();
  }

  Future<void> clearMandiPrices() async {
    return delete(mandiPrices).go();
  }

  // Order DAOs
  Future<OrderEntity?> getOrderById(String id) async {
    return (select(orders)..where((o) => o.id.equals(id))).getSingleOrNull();
  }

  Future<List<OrderEntity>> getUserOrders(String userId,
      {int limit = 20, int offset = 0}) async {
    return (select(orders)
          ..where((o) => o.userId.equals(userId))
          ..orderBy([(o) => OrderingTerm(expression: o.createdAt, mode: OrderingMode.desc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<OrderEntity>> getPendingOrders() async {
    return (select(orders)
          ..where((o) => o.synced.equals(false))
          ..orderBy([(o) => OrderingTerm(expression: o.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  Future<void> insertOrder(OrdersCompanion order) async {
    return into(orders).insert(order);
  }

  Future<void> updateOrder(OrdersCompanion order) async {
    return update(orders).replace(order);
  }

  Future<void> markOrderAsSynced(String orderId) async {
    return (update(orders)..where((o) => o.id.equals(orderId))).write(
      const OrdersCompanion(synced: Value(true)),
    );
  }

  Future<void> deleteOrder(String id) async {
    return (delete(orders)..where((o) => o.id.equals(id))).go();
  }

  // Pending Sync DAOs
  Future<PendingSyncEntity?> getPendingSyncById(String id) async {
    return (select(pendingSync)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<PendingSyncEntity>> getPendingSyncItems(
      {int limit = 50, int offset = 0}) async {
    return (select(pendingSync)
          ..where((p) => p.status.equals('pending'))
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.asc)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<PendingSyncEntity>> getFailedSyncItems() async {
    return (select(pendingSync)
          ..where((p) => p.status.equals('failed'))
          ..orderBy([(p) => OrderingTerm(expression: p.lastRetryAt, mode: OrderingMode.asc)]))
        .get();
  }

  Future<void> insertPendingSync(PendingSyncCompanion sync) async {
    return into(pendingSync).insertOnConflictUpdate(sync);
  }

  Future<void> updatePendingSyncStatus(
    String id,
    String status, {
    String? failureReason,
  }) async {
    return (update(pendingSync)..where((p) => p.id.equals(id))).write(
      PendingSyncCompanion(
        status: Value(status),
        failureReason: Value(failureReason),
        lastRetryAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> incrementPendingSyncRetryCount(String id) async {
    final item = await getPendingSyncById(id);
    if (item != null) {
      await (update(pendingSync)..where((p) => p.id.equals(id))).write(
        PendingSyncCompanion(
          retryCount: Value(item.retryCount + 1),
          lastRetryAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> deletePendingSync(String id) async {
    return (delete(pendingSync)..where((p) => p.id.equals(id))).go();
  }

  Future<void> clearSyncedItems() async {
    return (delete(pendingSync)..where((p) => p.status.equals('synced'))).go();
  }

  // Village DAOs
  Future<VillageEntity?> getVillageById(String id) async {
    return (select(villages)..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  Future<List<VillageEntity>> getVillagesByDistrict(String district) async {
    return (select(villages)..where((v) => v.district.equals(district))).get();
  }

  Future<List<VillageEntity>> getAllVillages() async {
    return select(villages).get();
  }

  Future<void> insertVillage(VillagesCompanion village) async {
    return into(villages).insertOnConflictUpdate(village);
  }

  Future<void> insertVillages(List<VillagesCompanion> villageList) async {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(villages, villageList);
    });
  }

  // ── Crop Listing DAOs ──
  Future<List<CropListingEntity>> getUserListings(String userId) async {
    return (select(cropListings)
          ..where((l) => l.userId.equals(userId))
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<CropListingEntity?> getCropListingById(String id) async {
    return (select(cropListings)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertCropListing(CropListingsCompanion listing) async {
    return into(cropListings).insertOnConflictUpdate(listing);
  }

  Future<void> updateCropListingStatus(String id, String status, {bool? synced}) async {
    await (update(cropListings)..where((l) => l.id.equals(id))).write(
      CropListingsCompanion(
        status: Value(status),
        synced: synced != null ? Value(synced) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<CropListingEntity>> getUnsyncedListings() async {
    return (select(cropListings)..where((l) => l.synced.equals(false) & l.status.equals('pending_sync'))).get();
  }

  // ── Product DAOs ──
  Future<List<ProductEntity>> getProductsByCategory(String category) async {
    return (select(products)..where((p) => p.category.equals(category))).get();
  }

  Future<List<ProductEntity>> searchProducts(String query) async {
    return (select(products)
          ..where((p) => p.name.like('%$query%') | p.nameLocal.like('%$query%'))
          ..limit(20))
        .get();
  }

  Future<ProductEntity?> getProductById(String id) async {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertProducts(List<ProductsCompanion> productList) async {
    return batch((b) {
      b.insertAllOnConflictUpdate(products, productList);
    });
  }

  Future<List<String>> getProductCategories() async {
    final result = await customSelect(
      'SELECT DISTINCT category FROM products ORDER BY category',
    ).get();
    return result.map((row) => row.read<String>('category')).toList();
  }

  // ── Cart DAOs ──
  Future<List<CartItemEntity>> getCartItems() async {
    return (select(cartItems)..orderBy([(c) => OrderingTerm(expression: c.addedAt, mode: OrderingMode.desc)])).get();
  }

  Future<void> addToCart(CartItemsCompanion item) async {
    return into(cartItems).insertOnConflictUpdate(item);
  }

  Future<void> updateCartItemQuantity(String id, int quantity) async {
    await (update(cartItems)..where((c) => c.id.equals(id))).write(
      CartItemsCompanion(quantity: Value(quantity)),
    );
  }

  Future<void> removeFromCart(String id) async {
    return (delete(cartItems)..where((c) => c.id.equals(id))).go();
  }

  Future<void> clearCart() async {
    return delete(cartItems).go();
  }

  Stream<List<CartItemEntity>> watchCartItems() {
    return (select(cartItems)..orderBy([(c) => OrderingTerm(expression: c.addedAt)])).watch();
  }

  // ── Payment Pending DAOs ──
  Future<void> insertPaymentPending(PaymentsPendingCompanion payment) async {
    return into(paymentsPending).insertOnConflictUpdate(payment);
  }

  Future<PaymentPendingEntity?> getPaymentByOrderId(String orderId) async {
    return (select(paymentsPending)..where((p) => p.orderId.equals(orderId))).getSingleOrNull();
  }

  Future<PaymentPendingEntity?> getPaymentByRazorpayOrderId(String rpOrderId) async {
    return (select(paymentsPending)..where((p) => p.razorpayOrderId.equals(rpOrderId))).getSingleOrNull();
  }

  Future<List<PaymentPendingEntity>> getInitiatedPayments() async {
    return (select(paymentsPending)..where((p) => p.status.equals('initiated'))).get();
  }

  Future<void> updatePaymentStatus(String id, String status, {String? razorpayPaymentId, String? razorpaySignature, String? failureReason}) async {
    await (update(paymentsPending)..where((p) => p.id.equals(id))).write(
      PaymentsPendingCompanion(
        status: Value(status),
        razorpayPaymentId: razorpayPaymentId != null ? Value(razorpayPaymentId) : const Value.absent(),
        razorpaySignature: razorpaySignature != null ? Value(razorpaySignature) : const Value.absent(),
        failureReason: failureReason != null ? Value(failureReason) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> incrementPaymentPollCount(String id) async {
    final payment = await (select(paymentsPending)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (payment != null) {
      await (update(paymentsPending)..where((p) => p.id.equals(id))).write(
        PaymentsPendingCompanion(pollCount: Value(payment.pollCount + 1), updatedAt: Value(DateTime.now())),
      );
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'kheteebaadi');
}
