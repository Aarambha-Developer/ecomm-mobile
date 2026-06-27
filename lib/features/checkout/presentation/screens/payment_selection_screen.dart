import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';
import 'package:aarambha_app/core/utils/toast_utils.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/order_request.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:aarambha_app/features/checkout/presentation/providers/payment_selection_provider.dart';
import 'package:aarambha_app/features/checkout/presentation/screens/order_success_screen.dart';

class PaymentSelectionScreen extends ConsumerStatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  ConsumerState<PaymentSelectionScreen> createState() =>
      _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState
    extends ConsumerState<PaymentSelectionScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _appliedCouponCode;

  String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    const baseDomain = 'https://ecom.aitrc.com.np';
    if (path.startsWith('/')) {
      return '$baseDomain$path';
    }
    return '$baseDomain/$path';
  }

  Future<void> _downloadQrCode(String imageUrl) async {
    try {
      if (!mounted) return;
      AppToast.showInfo(context, "Downloading QR Code...");

      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) throw Exception("Failed to download image bytes");

      await Gal.putImageBytes(Uint8List.fromList(bytes));

      if (mounted) {
        AppToast.showSuccess(context, "QR Code saved to gallery!");
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Failed to save QR Code: ${e.toString()}");
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 70,
    );
    if (picked != null) {
      ref
          .read(paymentSelectionProvider.notifier)
          .setScreenshotPath(picked.path);
    }
  }

  Future<void> _completeCheckout() async {
    final address = _addressController.text.trim();
    if (address.length < 10) {
      AppToast.showError(context, 'Please enter a valid shipping address');
      return;
    }

    final notifier = ref.read(paymentSelectionProvider.notifier);
    final orderId = await notifier.completeCheckout(
      orderRequest: OrderRequest(
        shippingAddress: address,
        notes: _notesController.text.trim(),
      ),
      couponCode: _appliedCouponCode,
    );

    if (!mounted) return;

    if (orderId != null) {
      unawaited(ref.read(cartProvider.notifier).loadCart());
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );
      return;
    }

    final message = ref.read(paymentSelectionProvider).errorMessage;
    if (message != null && message.isNotEmpty) {
      AppToast.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSelectionProvider);
    final selected = state.selectedMethod;
    final cart = ref.watch(cartProvider).valueOrNull;

    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, String?> && _appliedCouponCode == null) {
      final couponCode = extra['couponCode'];
      final couponRateStr = extra['couponRate'];
      if (couponCode != null && couponCode.isNotEmpty) {
        _appliedCouponCode = couponCode;
        if (couponRateStr != null) {
          final rate = double.tryParse(couponRateStr);
          if (rate != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ref
                    .read(paymentSelectionProvider.notifier)
                    .applyCouponLocally(rate);
              }
            });
          }
        }
      }
    }
    final subtotal = cart?.totalAmount ?? 0;
    final discountRate = state.couponDiscountRate;
    final discount = discountRate != null ? subtotal * (discountRate / 100) : 0.0;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/cart'),
        ),
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () =>
                ref.read(paymentSelectionProvider.notifier).loadMethods(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (cart != null && cart.items.isNotEmpty) ...[
                  _SectionCard(
                    title: 'Order Summary',
                    child: Column(
                      children: [
                        ...cart.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}  ${Formatters.formatCurrency(item.subtotal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(Formatters.formatCurrencyPlain(subtotal)),
                          ],
                        ),
                        if (discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount (${discountRate!.round()}%)',
                                style:
                                    const TextStyle(color: AppColors.success),
                              ),
                              Text(
                                '- ${Formatters.formatCurrencyPlain(discount)}',
                                style:
                                    const TextStyle(color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              Formatters.formatCurrency(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Street, city, state, zip code, country...',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimum 10 characters required',
                  style: TextStyle(
                    fontSize: 12,
                    color: _addressController.text.trim().length >= 10
                        ? AppColors.success
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Order Notes (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (_appliedCouponCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Coupon $_appliedCouponCode applied',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.methods.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No active COD/QR payment methods available.\nPlease contact support.',
                      ),
                    ),
                  )
                else
                  Column(
                    children: state.methods
                        .map((method) {
                          final isSelected =
                              method.id == state.selectedMethodId;
                          return _PaymentMethodTile(
                            method: method,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(paymentSelectionProvider.notifier)
                                .selectMethod(method.id),
                          );
                        })
                        .toList(),
                  ),
                const SizedBox(height: 12),
                if (selected != null)
                  _buildSelectedMethodDetails(selected, state),
                const SizedBox(height: 92),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ||
                          _addressController.text.trim().length < 10 ||
                          !state.canCheckout
                      ? null
                      : _completeCheckout,
                  child: Text(
                      'Place Order${discountRate != null ? ' (${discountRate.round()}% off)' : ''}'),
                ),
              ),
            ),
          ),
          if (state.isSubmitting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedMethodDetails(
    PaymentMethod method,
    PaymentSelectionState state,
  ) {
    if (method.isCod) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('Pay with cash upon delivery'),
        ),
      );
    }

    if (method.isQr) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (method.qrImage != null && method.qrImage!.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Image.network(
                            _resolveImageUrl(method.qrImage!),
                            height: 250,
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _downloadQrCode(_resolveImageUrl(method.qrImage!)),
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Save QR Code to Gallery'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (method.accountName != null && method.accountName!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Account Name: ${method.accountName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: method.accountName!));
                        AppToast.showSuccess(context, 'Account Name copied!');
                      },
                      tooltip: 'Copy Account Name',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (method.accountNumber != null && method.accountNumber!.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Account Number: ${method.accountNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: method.accountNumber!));
                        AppToast.showSuccess(context, 'Account Number copied!');
                      },
                      tooltip: 'Copy Account Number',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (method.instructions != null && method.instructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(method.instructions!),
              ],
              const SizedBox(height: 14),
              const Text(
                'Upload Payment Screenshot',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickScreenshot,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  state.screenshotPath == null
                      ? 'Choose from gallery'
                      : 'Change screenshot',
                ),
              ),
              if (state.screenshotPath != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(state.screenshotPath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      method.isCod ? 'Cash on delivery' : 'QR transfer',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
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
