import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/repositories/cart_repository.dart';
import '../../data/models/cart.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.read(apiClientProvider));
});

final storageProvider = Provider<SecureStorage>((ref) {
  return ref.read(apiClientProvider).storage;
});

class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  final CartRepository _repository;
  final SecureStorage _storage;

  CartNotifier(this._repository, this._storage)
      : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final hasTokens = await _storage.hasTokens();
      if (!hasTokens) {
        state = const AsyncValue.data(Cart(id: ''));
        return;
      }
      final cart = await _repository.getCart();
      state = AsyncValue.data(cart);
    } catch (_) {
      final previous = state;
      if (previous is! AsyncData) {
        state = const AsyncValue.data(Cart(id: ''));
      }
    }
  }

  Future<void> addItem({
    required String productId,
    int quantity = 1,
  }) async {
    final previous = state;
    try {
      final cart = await _repository.addItem(
        productId: productId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);
    } catch (e, _) {
      if (previous is AsyncData) {
        state = previous;
      }
    }
  }

  Future<void> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update
    final updatedItems = current.items.map((item) {
      if (item.id == itemId) {
        final newSubtotal = item.unitPrice * quantity;
        return CartItem(
          id: item.id,
          productId: item.productId,
          productName: item.productName,
          productSlug: item.productSlug,
          productImage: item.productImage,
          unitPrice: item.unitPrice,
          subtotal: newSubtotal,
          quantity: quantity,
          stockQuantity: item.stockQuantity,
        );
      }
      return item;
    }).toList();

    final newTotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    state = AsyncValue.data(Cart(
      id: current.id,
      items: updatedItems,
      totalItems: updatedItems.length,
      totalAmount: newTotal,
    ));

    try {
      final cart = await _repository.updateItemQuantity(
        itemId: itemId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await loadCart();
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      // Optimistic remove
      final current = state.valueOrNull;
      if (current != null) {
        final filtered = current.items.where((i) => i.id != itemId).toList();
        state = AsyncValue.data(Cart(
          id: current.id,
          items: filtered,
          totalItems: filtered.length,
          totalAmount: filtered.fold<double>(
            0,
            (sum, item) => sum + item.subtotal,
          ),
        ));
      }
      await _repository.removeItem(itemId);
      await loadCart();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await loadCart();
    }
  }

  Future<void> clearCart() async {
    try {
      await _repository.clearCart();
      state = const AsyncValue.data(Cart(id: ''));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart>>((ref) {
  return CartNotifier(
    ref.read(cartRepositoryProvider),
    ref.read(storageProvider),
  );
});
