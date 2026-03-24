import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kheteebaadi/database/app_database.dart';
import 'package:kheteebaadi/features/store/domain/entities/cart_item.dart';
import 'package:kheteebaadi/features/store/data/models/cart_item_model.dart';

// Cart notifier to manage cart state
class CartNotifier extends StateNotifier<List<CartItem>> {
  final AppDatabase database;

  CartNotifier({required this.database}) : super([]) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await database.cartItems.select().get();
    state = items
        .map((e) => CartItemModel(
              id: e.id,
              productId: e.productId,
              productName: e.productName,
              unitPrice: e.unitPrice,
              quantity: e.quantity,
              imageUrl: e.imageUrl,
              addedAt: e.addedAt,
            ))
        .toList();
  }

  Future<void> addToCart({
    required int productId,
    required String productName,
    required double unitPrice,
    required String imageUrl,
    int quantity = 1,
  }) async {
    final existingItem = state.firstWhereOrNull(
      (item) => item.productId == productId,
    );

    if (existingItem != null) {
      // Update quantity if item already exists
      await updateQuantity(existingItem.id, existingItem.quantity + quantity);
    } else {
      // Add new item
      final cartItem = CartItemsCompanion(
        productId: drift.Value(productId),
        productName: drift.Value(productName),
        unitPrice: drift.Value(unitPrice),
        quantity: drift.Value(quantity),
        imageUrl: drift.Value(imageUrl),
        addedAt: drift.Value(DateTime.now()),
      );

      final id = await database.into(database.cartItems).insert(cartItem);
      final newItem = CartItemModel(
        id: id,
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
        imageUrl: imageUrl,
        addedAt: DateTime.now(),
      );

      state = [...state, newItem];
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    await (database.cartItems.delete()
          ..where((tbl) => tbl.id.equals(cartItemId)))
        .go();
    state = state.where((item) => item.id != cartItemId).toList();
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    final updatedItem = state.firstWhereOrNull((item) => item.id == cartItemId);
    if (updatedItem != null) {
      await (database.cartItems.update()
            ..where((tbl) => tbl.id.equals(cartItemId)))
          .write(CartItemsCompanion(quantity: drift.Value(newQuantity)));

      state = state
          .map((item) =>
              item.id == cartItemId
                  ? CartItemModel(
                      id: item.id,
                      productId: item.productId,
                      productName: item.productName,
                      unitPrice: item.unitPrice,
                      quantity: newQuantity,
                      imageUrl: item.imageUrl,
                      addedAt: item.addedAt,
                    )
                  : item)
          .toList();
    }
  }

  Future<void> clearCart() async {
    await database.cartItems.delete().go();
    state = [];
  }

  double getCartTotal() {
    return state.fold<double>(0, (total, item) => total + item.totalPrice);
  }

  int getItemCount() {
    return state.fold<int>(0, (total, item) => total + item.quantity);
  }
}

// Cart provider
final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CartNotifier(database: database);
});

// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  final cartNotifier = ref.watch(cartProvider.notifier);
  return cartNotifier.getCartTotal();
});

// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartNotifier = ref.watch(cartProvider.notifier);
  return cartNotifier.getItemCount();
});

// Cart total items count (different from item count, counts unique items)
final cartItemsCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.length;
});

// App database provider (if not already defined elsewhere)
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Extension for firstWhereOrNull
extension FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
