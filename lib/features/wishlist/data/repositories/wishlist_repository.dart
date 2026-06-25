import '../../../../core/network/api_client.dart';
import '../datasources/wishlist_remote_source.dart';
import '../models/wishlist.dart';

class WishlistRepository {
  final WishlistRemoteSource _remoteSource;

  WishlistRepository(ApiClient client)
      : _remoteSource = WishlistRemoteSource(client);

  Future<Wishlist> getWishlist() async {
    final response = await _remoteSource.getWishlist();
    final data = response['data'];
    if (data is Map) {
      return Wishlist.fromJson(Map<String, dynamic>.from(data));
    }
    return const Wishlist(id: '');
  }

  Future<Wishlist> addItem(String productId) async {
    await _remoteSource.addItem(productId);
    return getWishlist();
  }

  Future<Wishlist> removeItem(String itemId) async {
    await _remoteSource.removeItem(itemId);
    return getWishlist();
  }

  Future<void> clearWishlist() async {
    await _remoteSource.clearWishlist();
  }
}
