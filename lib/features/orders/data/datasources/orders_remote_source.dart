import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class OrdersRemoteSource {
  final ApiClient _client;

  OrdersRemoteSource(this._client);

  Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    return await _client.get(
      ApiConstants.orders,
      queryParameters: {'page': page},
    );
  }

  Future<Map<String, dynamic>> getRecentOrders() async {
    return await _client.get(ApiConstants.ordersRecent);
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    return await _client.get('${ApiConstants.orders}$id/');
  }
}
