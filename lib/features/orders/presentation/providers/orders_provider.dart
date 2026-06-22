import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/orders/data/repositories/orders_repository.dart';
import 'package:aarambha_app/features/orders/data/datasources/orders_remote_source.dart';
import 'package:aarambha_app/features/orders/data/models/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return OrdersRepository(OrdersRemoteSource(apiClient));
});

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(ordersRepositoryProvider);
  return await repo.getOrders();
});

final recentOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(ordersRepositoryProvider);
  return await repo.getRecentOrders();
});

final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, id) async {
  final repo = ref.read(ordersRepositoryProvider);
  return await repo.getOrder(id);
});
