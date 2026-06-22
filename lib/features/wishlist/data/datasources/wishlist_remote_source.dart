import 'package:aarambha_app/core/network/api_client.dart';
import 'package:aarambha_app/core/constants/api_constants.dart';

class WishlistRemoteSource {
  final ApiClient _client;

  WishlistRemoteSource(this._client);

  Future<Map<String, dynamic>> getWishlist() async {
    return await _client.get(ApiConstants.wishlist);
  }

  Future<Map<String, dynamic>> addItem(String productId) async {
    return await _client.post(
      ApiConstants.wishlistItems,
      data: {'product_id': productId},
    );
  }

  Future<void> removeItem(String itemId) async {
    await _client.delete('${ApiConstants.wishlistItems}$itemId/');
  }

  Future<void> clearWishlist() async {
    await _client.delete(ApiConstants.wishlistClear);
  }
}
