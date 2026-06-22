import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/checkout/data/models/payment_method.dart';
import 'package:aarambha_app/features/checkout/data/repositories/checkout_repository.dart';
import 'package:aarambha_app/features/checkout/presentation/screens/payment_webview_screen.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.read(apiClientProvider));
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final repo = ref.read(checkoutRepositoryProvider);
  return await repo.getPaymentMethods();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _pageController = PageController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponController = TextEditingController();
  String? _selectedPaymentMethodId;
  String? _screenshotPath;
  double? _couponDiscount;
  bool _isPlacing = false;
  bool _isValidatingCoupon = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _screenshotPath = file.path);
    }
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final discount = await repo.validateCoupon(code);
      setState(() => _couponDiscount = discount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied! ${discount.round()}% off')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid coupon: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final selectedMethod = ref
          .read(paymentMethodsProvider)
          .valueOrNull
          ?.where((m) => m.id == _selectedPaymentMethodId)
          .firstOrNull;

      final result = await repo.placeOrder(
        shippingAddress: _addressController.text.trim(),
        paymentMethodId: _selectedPaymentMethodId!,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        couponCode: _couponDiscount != null
            ? _couponController.text.trim()
            : null,
        paymentScreenshotPath:
            selectedMethod?.isQr == true ? _screenshotPath : null,
      );

      if (result.requiresGatewayRedirect && result.paymentUrl != null) {
        if (mounted) {
          final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PaymentWebViewScreen(
                url: result.paymentUrl!,
                orderId: result.orderId ?? '',
              ),
            ),
          );
          if (success != true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment was not completed')),
            );
          }
        }
      }

      if (mounted) {
        ref.read(cartProvider.notifier).loadCart();
        context.push('/orders/${result.orderId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final cartAsync = ref.watch(cartProvider);
    final cart = cartAsync.valueOrNull;
    final subtotal = cart?.totalAmount ?? 0;
    final discount = _couponDiscount != null
        ? subtotal * (_couponDiscount! / 100)
        : 0.0;
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _AddressStep(controller: _addressController),
                _PaymentStep(
                  paymentMethodsAsync: paymentMethodsAsync,
                  selectedMethodId: _selectedPaymentMethodId,
                  onMethodSelected: (id) =>
                      setState(() => _selectedPaymentMethodId = id),
                  screenshotPath: _screenshotPath,
                  onPickScreenshot: _pickScreenshot,
                ),
                _ReviewStep(
                  cart: cart,
                  addressController: _addressController,
                  notesController: _notesController,
                  couponController: _couponController,
                  couponDiscount: _couponDiscount,
                  isValidatingCoupon: _isValidatingCoupon,
                  onValidateCoupon: _validateCoupon,
                  subtotal: subtotal,
                  discount: discount,
                  total: total,
                ),
              ],
            ),
          ),
          _StepIndicator(currentStep: _currentStep, totalSteps: 3),
          _BottomNav(
            currentStep: _currentStep,
            totalSteps: 3,
            isPlacing: _isPlacing,
            canProceed: _canProceed(),
            onBack: () => _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            onNext: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
            onPlaceOrder: _placeOrder,
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _addressController.text.trim().length >= 10;
      case 1:
        if (_selectedPaymentMethodId == null) return false;
        final method = ref
            .read(paymentMethodsProvider)
            .valueOrNull
            ?.where((m) => m.id == _selectedPaymentMethodId)
            .firstOrNull;
        if (method?.isQr == true && _screenshotPath == null) return false;
        return true;
      case 2:
        return true; // Just review, place button handles validation
      default:
        return false;
    }
  }
}

class _AddressStep extends StatelessWidget {
  final TextEditingController controller;

  const _AddressStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Shipping Address',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your full shipping address',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Street, city, state, zip code, country...',
              alignLabelWithHint: true,
            ),
            onChanged: (_) => (context as Element).markNeedsBuild(),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum 10 characters required',
            style: TextStyle(
              fontSize: 12,
              color: controller.text.length < 10
                  ? AppColors.textHint
                  : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final AsyncValue<List<PaymentMethod>> paymentMethodsAsync;
  final String? selectedMethodId;
  final ValueChanged<String> onMethodSelected;
  final String? screenshotPath;
  final VoidCallback onPickScreenshot;

  const _PaymentStep({
    required this.paymentMethodsAsync,
    required this.selectedMethodId,
    required this.onMethodSelected,
    this.screenshotPath,
    required this.onPickScreenshot,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Payment Method', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          paymentMethodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (methods) => Column(
              children: methods.map((method) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: RadioListTile<String>(
                    title: Text(method.title),
                    subtitle: Text(
                      method.isCod
                          ? 'Pay on delivery'
                          : method.isGateway
                              ? 'Online payment gateway'
                              : 'QR / Bank transfer',
                    ),
                    value: method.id,
                    groupValue: selectedMethodId,
                    onChanged: (v) {
                      if (v != null) onMethodSelected(v);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          if (selectedMethodId != null) ...[
            const SizedBox(height: 16),
            _PaymentMethodDetail(
              methodId: selectedMethodId!,
              screenshotPath: screenshotPath,
              onPickScreenshot: onPickScreenshot,
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodDetail extends ConsumerWidget {
  final String methodId;
  final String? screenshotPath;
  final VoidCallback onPickScreenshot;

  const _PaymentMethodDetail({
    required this.methodId,
    this.screenshotPath,
    required this.onPickScreenshot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ?? [];
    final method = methods.where((m) => m.id == methodId).firstOrNull;
    if (method == null) return const SizedBox.shrink();

    if (method.isQr) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Details',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (method.accountName != null)
            Text('Account: ${method.accountName}'),
          if (method.accountNumber != null)
            Text('Number: ${method.accountNumber}'),
          if (method.qrImage != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: method.qrImage!,
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Upload Payment Screenshot',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickScreenshot,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: screenshotPath != null
                      ? AppColors.success
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: screenshotPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(screenshotPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt,
                              color: AppColors.textHint, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Tap to upload screenshot',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    if (method.isGateway) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'You will be redirected to the payment gateway after placing the order.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ReviewStep extends StatelessWidget {
  final dynamic cart;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final TextEditingController couponController;
  final double? couponDiscount;
  final bool isValidatingCoupon;
  final VoidCallback onValidateCoupon;
  final double subtotal;
  final double discount;
  final double total;

  const _ReviewStep({
    required this.cart,
    required this.addressController,
    required this.notesController,
    required this.couponController,
    this.couponDiscount,
    required this.isValidatingCoupon,
    required this.onValidateCoupon,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Review Order', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Shipping Address',
            child: Text(addressController.text),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Order Notes (optional)',
              hintText: 'Any special instructions...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: couponController,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'Enter code',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    isValidatingCoupon ? null : onValidateCoupon,
                child: isValidatingCoupon
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Order Summary',
            child: Column(
              children: [
                _SummaryRow(label: 'Subtotal', value: 'Rs. $subtotal'),
                if (discount > 0)
                  _SummaryRow(
                    label: 'Discount (${couponDiscount?.round()}%)',
                    value: '- Rs. ${discount.toStringAsFixed(2)}',
                    valueColor: AppColors.success,
                  ),
                const Divider(),
                _SummaryRow(
                  label: 'Total',
                  value: 'Rs. ${total.toStringAsFixed(total == total.round() ? 0 : 2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (cart?.items != null)
            ...List.generate(
              (cart.items as List).length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${(cart.items[i] as dynamic).productName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      'x${(cart.items[i] as dynamic).quantity}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isPlacing;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onPlaceOrder;

  const _BottomNav({
    required this.currentStep,
    required this.totalSteps,
    required this.isPlacing,
    required this.canProceed,
    required this.onBack,
    required this.onNext,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0)
              OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canProceed
                    ? (isLastStep ? onPlaceOrder : onNext)
                    : null,
                child: isPlacing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(isLastStep ? 'Place Order' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
