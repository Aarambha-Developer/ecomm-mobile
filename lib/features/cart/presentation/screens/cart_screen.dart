import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';
import 'package:aarambha_app/core/utils/toast_utils.dart';
import 'package:aarambha_app/core/storage/local_cart_provider.dart';
import 'package:aarambha_app/core/widgets/empty_state.dart';
import 'package:aarambha_app/core/widgets/price_display.dart';
import 'package:aarambha_app/core/widgets/loading_widget.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/cart/data/models/cart.dart';
import 'package:aarambha_app/features/checkout/data/services/payment_api_service.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoController = TextEditingController();
  bool _isValidatingCoupon = false;
  double? _couponDiscountRate;
  String? _couponError;
  String? _appliedCouponCode;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final isLoggedIn = ref.read(authProvider).status == AuthStatus.authenticated;
      String cartTotal;
      List<String> productIds;

      if (isLoggedIn) {
        final cart = ref.read(cartProvider).valueOrNull;
        cartTotal = (cart?.totalAmount ?? 0.0).toStringAsFixed(2);
        productIds = cart?.items.map((i) => i.productId).where((id) => id.isNotEmpty).toList() ?? [];
      } else {
        final cart = ref.read(localCartProvider);
        cartTotal = cart.totalAmount.toStringAsFixed(2);
        productIds = cart.items.map((i) => i.productId).where((id) => id.isNotEmpty).toList();
      }

      final service = PaymentApiService(ref.read(apiClientProvider));
      final rate = await service.validateCoupon(
        code: code,
        cartTotal: cartTotal,
        productIds: productIds,
      );
      setState(() {
        _couponDiscountRate = rate;
        _appliedCouponCode = code;
        _isValidatingCoupon = false;
      });
      if (mounted) {
        AppToast.showSuccess(context, 'Coupon applied! ${rate.round()}% off');
      }
    } catch (e) {
      setState(() {
        _couponError = e.toString();
        _couponDiscountRate = null;
        _appliedCouponCode = null;
        _isValidatingCoupon = false;
      }      );
      if (mounted) {
        AppToast.showError(context, 'Invalid coupon: $_couponError');
      }
    }
  }

  void _clearCoupon() {
    setState(() {
      _promoController.clear();
      _couponDiscountRate = null;
      _appliedCouponCode = null;
      _couponError = null;
    });
  }

  double _calculateTotal(double subtotal) {
    if (_couponDiscountRate == null) return subtotal;
    return subtotal * (1 - _couponDiscountRate! / 100);
  }

  void _goToCheckout() {
    final extra = <String, String?>{};
    if (_appliedCouponCode != null) {
      extra['couponCode'] = _appliedCouponCode;
    }
    if (_couponDiscountRate != null) {
      extra['couponRate'] = _couponDiscountRate!.toString();
    }
    context.push('/checkout', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.status == AuthStatus.authenticated;

    final serverCart = ref.watch(cartProvider);
    final localCart = ref.watch(localCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (isLoggedIn)
            serverCart.whenOrNull(
                  data: (cart) => cart.items.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _clearServerCart(ref, context),
                        )
                      : null,
                ) ??
                const SizedBox.shrink(),
          if (!isLoggedIn && localCart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                ref.read(localCartProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: _buildCartBody(context, ref, isLoggedIn, serverCart, localCart),
      ),
    );
  }

  Widget _buildCartBody(BuildContext context, WidgetRef ref, bool isLoggedIn,
      AsyncValue<Cart> serverCart, LocalCart localCart) {
    if (isLoggedIn) {
      final serverData = serverCart.valueOrNull;
      if (serverData != null && serverData.items.isNotEmpty) {
        return _buildServerCart(context, ref, serverCart);
      }
      if (localCart.items.isNotEmpty) {
        return _buildLocalCart(context, ref, localCart, isLoggedIn: true);
      }
      return _buildServerCart(context, ref, serverCart);
    }
    return _buildLocalCart(context, ref, localCart, isLoggedIn: false);
  }

  Widget _buildServerCart(
      BuildContext context, WidgetRef ref, AsyncValue<Cart> cartAsync) {
    return cartAsync.when(
      loading: () => const LoadingWidget(message: 'Loading cart...'),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load cart',
                style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(cartProvider.notifier).loadCart(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (cart) {
        if (cart.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is empty',
            subtitle: 'Browse products and add items to your cart',
            actionLabel: 'Start Shopping',
            onAction: () => context.go('/'),
          );
        }

        final subtotal = cart.totalAmount;
        final discountedTotal = _calculateTotal(subtotal);

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: cart.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return _ServerCartItemTile(
                    item: item,
                    onQuantityChanged: (qty) {
                      ref.read(cartProvider.notifier).updateQuantity(
                            itemId: item.id,
                            quantity: qty,
                          );
                    },
                    onRemove: () {
                      ref.read(cartProvider.notifier).removeItem(item.id);
                    },
                  );
                },
              ),
            ),
            _buildCouponSection(),
            _CartBottomBar(
              totalAmount: subtotal,
              discountedTotal: discountedTotal,
              discountPercent: _couponDiscountRate,
              itemCount: cart.totalItems,
              onCheckout: _goToCheckout,
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocalCart(
    BuildContext context,
    WidgetRef ref,
    LocalCart localCart, {
    required bool isLoggedIn,
  }) {
    if (localCart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        subtitle: 'Browse products and add items to your cart',
        actionLabel: 'Start Shopping',
        onAction: () => context.go('/'),
      );
    }

    final subtotal = localCart.totalAmount;
    final discountedTotal = _calculateTotal(subtotal);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: localCart.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = localCart.items[index];
              return _LocalCartItemTile(
                item: item,
                onQuantityChanged: (qty) {
                  ref
                      .read(localCartProvider.notifier)
                      .updateQuantity(item.productId, qty);
                },
                onRemove: () {
                  ref
                      .read(localCartProvider.notifier)
                      .removeItem(item.productId);
                },
              );
            },
          ),
        ),
        _buildCouponSection(),
        _CartBottomBar(
          totalAmount: subtotal,
          discountedTotal: discountedTotal,
          discountPercent: _couponDiscountRate,
          itemCount: localCart.itemCount,
          onCheckout: () => context.push(
            isLoggedIn
                ? '/checkout'
                : '/login?redirect=${Uri.encodeComponent('/checkout')}',
          ),
        ),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Promo Code',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.white,
                suffixIcon: _appliedCouponCode != null
                    ? IconButton(
                        icon:
                            const Icon(Icons.close, size: 18),
                        onPressed: _clearCoupon,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed:
                _isValidatingCoupon || _promoController.text.trim().isEmpty
                    ? null
                    : _validateCoupon,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
            child: _isValidatingCoupon
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearServerCart(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(ctx).pop();
            },
            child:
                const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ServerCartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _ServerCartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _CartItemLayout(
      imageUrl: item.productImage,
      name: item.productName,
      unitPrice: item.unitPrice,
      subtotal: item.subtotal,
      basePrice: item.basePrice,
      baseSubtotal: item.baseSubtotal,
      quantity: item.quantity,
      onQuantityChanged: onQuantityChanged,
      onRemove: onRemove,
    );
  }
}

class _LocalCartItemTile extends StatelessWidget {
  final LocalCartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _LocalCartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _CartItemLayout(
      imageUrl: item.productImage,
      name: item.productName,
      unitPrice: item.price,
      subtotal: item.price * item.quantity,
      quantity: item.quantity,
      onQuantityChanged: onQuantityChanged,
      onRemove: onRemove,
    );
  }
}

class _CartItemLayout extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double unitPrice;
  final double subtotal;
  final double? basePrice;
  final double? baseSubtotal;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemLayout({
    this.imageUrl,
    required this.name,
    required this.unitPrice,
    required this.subtotal,
    this.basePrice,
    this.baseSubtotal,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasSavings = baseSubtotal != null && baseSubtotal! > subtotal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: AppColors.surfaceVariant,
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.image_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  PriceDisplay(
                    price: basePrice ?? unitPrice,
                    discountedPrice: (basePrice != null && basePrice! > unitPrice) ? unitPrice : null,
                    priceStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    discountedPriceStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.priceDiscounted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityControl(
                        quantity: quantity,
                        onDecrement: quantity > 1
                            ? () => onQuantityChanged(quantity - 1)
                            : null,
                        onIncrement: () => onQuantityChanged(quantity + 1),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.formatCurrency(subtotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.price,
                        ),
                      ),
                    ],
                  ),
                  if (hasSavings) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Saved ${Formatters.formatCurrency(baseSubtotal! - subtotal)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textHint),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.quantity,
    this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _QtyBtn(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.textPrimary : AppColors.textHint,
        ),
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final double totalAmount;
  final double discountedTotal;
  final double? discountPercent;
  final int itemCount;
  final VoidCallback onCheckout;

  const _CartBottomBar({
    required this.totalAmount,
    required this.discountedTotal,
    this.discountPercent,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountPercent != null && discountPercent! > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasDiscount)
                    Text(
                      Formatters.formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textHint,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    Formatters.formatCurrency(discountedTotal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.price,
                    ),
                  ),
                  if (hasDiscount)
                    Text(
                      '${discountPercent!.round()}% off',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text('Checkout ($itemCount)'),
            ),
          ],
        ),
      ),
    );
  }
}
