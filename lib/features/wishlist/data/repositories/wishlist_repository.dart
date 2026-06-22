import '../../../../core/network/api_client.dart';
import '../datasources/wishlist_remote_source.dart';
import '../models/wishlist.dart';

class WishlistRepository {
  final WishlistRemoteSource _remoteSource;

  WishlistRepository(ApiClient client)
      : _remoteSource = WishlistRemoteSource(client);

  Future<Wishlist> getWishlist() async {
    final response = await _remoteSource.getWishlist();
    return Wishlist.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Wishlist> addItem(String productId) async {
    final response = await _remoteSource.addItem(productId);
    return Wishlist.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Wishlist> removeItem(String itemId) async {
    await _remoteSource.removeItem(itemId);
    return const Wishlist(id: '');
  }

  Future<void> clearWishlist() async {
    await _remoteSource.clearWishlist();
  }
}
