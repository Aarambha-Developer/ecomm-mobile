import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:aarambha_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:aarambha_app/features/orders/data/models/order.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load orders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Start shopping to see your orders here'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(ordersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  _StatusChip(status: order.statusLabel, order: order),
                ],
              ),
              const SizedBox(height: 8),
              if (order.items.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final item = order.items[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item.productImage != null
                            ? CachedNetworkImage(
                                imageUrl: item.productImage!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.image, size: 20),
                                ),
                              )
                            : Container(
                                width: 48,
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.image, size: 20),
                              ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} item(s)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed: ${_formatDate(order.createdAt)}',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Order order;

  const _StatusChip({required this.status, required this.order});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (order.isDelivered || order.isRefunded) {
      color = AppColors.success;
    } else if (order.isCancelled) {
      color = AppColors.error;
    } else if (order.isProcessing || order.isShipped) {
      color = AppColors.warning;
    } else {
      color = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
