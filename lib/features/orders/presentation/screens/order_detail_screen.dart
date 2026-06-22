import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aarambha_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:aarambha_app/features/orders/data/models/order.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load order: $e'),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () => ref.refresh(orderDetailProvider(id).future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderHeader(order: order),
                const SizedBox(height: 20),
                if (order.shippingAddress != null) ...[
                  _Section(title: 'Shipping Address', child: Text(order.shippingAddress!)),
                  const SizedBox(height: 12),
                ],
                if (order.paymentMethod != null) ...[
                  _Section(
                    title: 'Payment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Method: ${order.paymentMethod}'),
                        if (order.paymentStatus != null)
                          Text('Status: ${order.paymentStatus}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _Section(
                  title: 'Items (${order.items.length})',
                  child: Column(
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            ClipRRect(
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
                                      height: 48,
                                      color: AppColors.primaryLight,
                                      child: const Icon(Icons.image, size: 20),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.formatCurrencyPlain(item.price * item.quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Summary',
                  child: Column(
                    children: [
                      _SummaryRow(label: 'Subtotal', value: Formatters.formatCurrencyPlain(order.totalAmount)),
                      if (order.discountAmount != null && order.discountAmount! > 0)
                        _SummaryRow(
                          label: order.couponCode != null
                              ? 'Discount (${order.couponCode})'
                              : 'Discount',
                          value: '- ${Formatters.formatCurrencyPlain(order.discountAmount!)}',
                          valueColor: AppColors.success,
                        ),
                      const Divider(),
                      _SummaryRow(
                        label: 'Total',
                        value: Formatters.formatCurrencyPlain(order.totalAmount),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Placed at: ${_formatDateTime(order.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _OrderHeader extends StatelessWidget {
  final Order order;

  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (order.isDelivered || order.isRefunded) {
      statusColor = AppColors.success;
    } else if (order.isCancelled) {
      statusColor = AppColors.error;
    } else if (order.isProcessing || order.isShipped) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.textHint;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                order.statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
