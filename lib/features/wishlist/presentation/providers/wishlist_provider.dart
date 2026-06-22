import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/core/storage/secure_storage.dart';
import 'package:aarambha_app/features/wishlist/data/repositories/wishlist_repository.dart';
import 'package:aarambha_app/features/wishlist/data/models/wishlist.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.read(apiClientProvider));
});

class WishlistNotifier extends StateNotifier<AsyncValue<Wishlist>> {
  final WishlistRepository _repository;
  final SecureStorage _storage;

  WishlistNotifier(this._repository, this._storage)
      : super(const AsyncValue.loading()) {
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    state = const AsyncValue.loading();
    try {
      final hasTokens = await _storage.hasTokens();
      if (!hasTokens) {
        state = const AsyncValue.data(Wishlist(id: ''));
        return;
      }
      final wishlist = await _repository.getWishlist();
      state = AsyncValue.data(wishlist);
    } catch (_) {
      state = const AsyncValue.data(Wishlist(id: ''));
    }
  }

  Future<bool> toggleItem(String productId) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    final existing = current.items.where(
      (item) => item.product.id == productId,
    );

    if (existing.isNotEmpty) {
      await removeItem(existing.first.id);
      return false;
    } else {
      await addItem(productId);
      return true;
    }
  }

  bool isWishlisted(String productId) {
    final current = state.valueOrNull;
    if (current == null) return false;
    return current.items.any((item) => item.product.id == productId);
  }

  Future<void> addItem(String productId) async {
    try {
      final wishlist = await _repository.addItem(productId);
      state = AsyncValue.data(wishlist);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeItem(String itemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.items.where((i) => i.id != itemId).toList();
    state = AsyncValue.data(Wishlist(id: current.id, items: updated));

    try {
      await _repository.removeItem(itemId);
      await loadWishlist();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await loadWishlist();
    }
  }

  Future<void> clearWishlist() async {
    try {
      await _repository.clearWishlist();
      state = const AsyncValue.data(Wishlist(id: ''));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, AsyncValue<Wishlist>>((ref) {
  return WishlistNotifier(
    ref.read(wishlistRepositoryProvider),
    ref.read(storageProvider),
  );
});
