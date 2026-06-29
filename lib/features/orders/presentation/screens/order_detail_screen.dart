import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aarambha_app/features/orders/presentation/providers/orders_provider.dart';
import 'package:aarambha_app/features/orders/data/models/order.dart';
import 'package:go_router/go_router.dart';
import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(id));

    final canPop = Navigator.canPop(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(canPop ? Icons.arrow_back_rounded : Icons.home_rounded),
          onPressed: () {
            if (canPop) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Order Detail'),
      ),
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
                Builder(
                  builder: (context) {
                    final address = order.formattedShippingAddress;
                    if (address == null || address.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        _Section(
                          title: 'Shipping Details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (order.shippingFullName != null && order.shippingFullName!.isNotEmpty) ...[
                                Text(
                                  order.shippingFullName!,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(address, style: const TextStyle(fontSize: 14)),
                              if (order.shippingPhone != null && order.shippingPhone!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      order.shippingPhone!,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              if (order.shippingEmail != null && order.shippingEmail!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      order.shippingEmail!,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                ),
                
                // Payment section
                Builder(
                  builder: (context) {
                    final proof = order.paymentProof;
                    final paymentMethod = order.paymentMethod ?? (proof != null ? 'QR / Bank Transfer' : 'Cash on Delivery (COD)');
                    return _Section(
                      title: 'Payment Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Method: $paymentMethod'),
                          if (order.paymentStatus != null) ...[
                            const SizedBox(height: 4),
                            Text('Status: ${order.paymentStatus!.toUpperCase()}'),
                          ],
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 12),

                // Payment Proof Verification section (if QR payment was chosen)
                if (order.paymentProof != null) ...[
                  Builder(
                    builder: (context) {
                      final proof = order.paymentProof!;
                      final proofScreenshot = proof['screenshot']?.toString();
                      final proofStatus = proof['status']?.toString();
                      final proofAdminNote = proof['admin_note']?.toString();
                      
                      return _Section(
                        title: 'Payment Verification',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Verification Status:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (proofStatus == 'verified'
                                            ? AppColors.success
                                            : proofStatus == 'rejected'
                                                ? AppColors.error
                                                : AppColors.warning)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    proofStatus?.toUpperCase() ?? 'PENDING',
                                    style: TextStyle(
                                      color: proofStatus == 'verified'
                                          ? AppColors.success
                                          : proofStatus == 'rejected'
                                              ? AppColors.error
                                              : AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (proofAdminNote != null && proofAdminNote.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Admin Note: $proofAdminNote',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (proofScreenshot != null && proofScreenshot.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Submitted Screenshot:',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: proofScreenshot,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 150,
                                    color: AppColors.primaryLight,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    height: 150,
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.broken_image, size: 40, color: AppColors.textHint),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }
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
                              child: item.productImage != null && item.productImage!.isNotEmpty
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
                      _SummaryRow(label: 'Subtotal', value: Formatters.formatCurrencyPlain(order.subtotalPrice > 0 ? order.subtotalPrice : order.totalAmount)),
                      if (order.discountAmount != null && order.discountAmount! > 0)
                        _SummaryRow(
                          label: order.coupon != null
                              ? 'Discount (${order.coupon})'
                              : 'Discount',
                          value: '- ${Formatters.formatCurrencyPlain(order.discountAmount!)}',
                          valueColor: AppColors.success,
                        ),
                      if (order.deliveryCharge != null)
                        _SummaryRow(
                          label: 'Delivery Charge',
                          value: order.deliveryCharge! > 0
                              ? Formatters.formatCurrencyPlain(order.deliveryCharge!)
                              : 'Free',
                          valueColor: order.deliveryCharge! > 0
                              ? null
                              : AppColors.success,
                        ),
                      const Divider(),
                      _SummaryRow(
                        label: 'Total',
                        value: Formatters.formatCurrencyPlain(order.totalPrice > 0 ? order.totalPrice : order.totalAmount),
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
    } else if (order.isConfirmed || order.isProcessing || order.isShipped) {
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
