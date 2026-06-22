import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class CartRemoteSource {
  final ApiClient _client;

  CartRemoteSource(this._client);

  Future<Map<String, dynamic>> getCart() async {
    return await _client.get(ApiConstants.cart);
  }

  Future<Map<String, dynamic>> addItem({
    required String productId,
    int quantity = 1,
  }) async {
    return await _client.post(
      ApiConstants.cartItems,
      data: {'product_id': productId, 'quantity': quantity},
    );
  }

  Future<Map<String, dynamic>> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    return await _client.patch(
      '${ApiConstants.cartItems}$itemId/',
      data: {'quantity': quantity},
    );
  }

  Future<void> removeItem(String itemId) async {
    await _client.delete('${ApiConstants.cartItems}$itemId/');
  }

  Future<void> clearCart() async {
    await _client.delete(ApiConstants.cartClear);
  }
}
