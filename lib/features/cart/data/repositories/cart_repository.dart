import '../../../../core/network/api_client.dart';
import '../datasources/cart_remote_source.dart';
import '../models/cart.dart';

class CartRepository {
  final CartRemoteSource _remoteSource;

  CartRepository(ApiClient client)
      : _remoteSource = CartRemoteSource(client);

  Future<Cart> getCart() async {
    final response = await _remoteSource.getCart();
    return Cart.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cart> addItem({required String productId, int quantity = 1}) async {
    final response = await _remoteSource.addItem(
      productId: productId,
      quantity: quantity,
    );
    return Cart.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cart> updateItemQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final response = await _remoteSource.updateItemQuantity(
      itemId: itemId,
      quantity: quantity,
    );
    return Cart.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cart> removeItem(String itemId) async {
    await _remoteSource.removeItem(itemId);
    return const Cart(id: '');
  }

  Future<void> clearCart() async {
    await _remoteSource.clearCart();
  }
}
