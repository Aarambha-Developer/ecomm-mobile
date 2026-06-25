import '../../../../core/network/api_client.dart';
import '../datasources/cart_remote_source.dart';
import '../models/cart.dart';

class CartRepository {
  final CartRemoteSource _remoteSource;

  CartRepository(ApiClient client)
      : _remoteSource = CartRemoteSource(client);

  Future<Cart> getCart() async {
    final response = await _remoteSource.getCart();
    final data = response['data'];
    if (data is Map) {
      return Cart.fromJson(Map<String, dynamic>.from(data));
    }
    return const Cart(id: '');
  }

  Future<Cart> addItem({required String productId, int quantity = 1}) async {
    await _remoteSource.addItem(
      productId: productId,
      quantity: quantity,
    );
    return await getCart();
  }

  Future<Cart> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    await _remoteSource.updateItemQuantity(
      itemId: itemId,
      quantity: quantity,
    );
    return await getCart();
  }

  Future<Cart> removeItem(String itemId) async {
    await _remoteSource.removeItem(itemId);
    return await getCart();
  }

  Future<void> clearCart() async {
    await _remoteSource.clearCart();
  }
}
