import 'package:aarambha_app/features/orders/data/datasources/orders_remote_source.dart';
import 'package:aarambha_app/features/orders/data/models/order.dart';

class OrdersRepository {
  final OrdersRemoteSource _remoteSource;

  OrdersRepository(this._remoteSource);

  Future<List<Order>> getOrders({int page = 1}) async {
    final response = await _remoteSource.getOrders(page: page);
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<List<Order>> getRecentOrders() async {
    final response = await _remoteSource.getRecentOrders();
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<Order> getOrder(String id) async {
    final response = await _remoteSource.getOrder(id);
    final data = response['data'];
    if (data is Map) {
      return Order.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid order response format');
  }
}
