import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/utils/formatters.dart';
import 'package:aarambha_app/core/storage/local_cart_provider.dart';
import 'package:aarambha_app/core/widgets/empty_state.dart';
import 'package:aarambha_app/core/widgets/price_display.dart';
import 'package:aarambha_app/core/widgets/loading_widget.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:aarambha_app/features/cart/data/models/cart.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: _buildCartBody(context, ref, isLoggedIn, serverCart, localCart),
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
        return _buildLocalCart(context, ref, localCart);
      }
      return _buildServerCart(context, ref, serverCart);
    }
    return _buildLocalCart(context, ref, localCart);
  }

  Widget _buildServerCart(BuildContext context, WidgetRef ref, AsyncValue<Cart> cartAsync) {
    return cartAsync.when(
      loading: () => const LoadingWidget(message: 'Loading cart...'),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load cart', style: TextStyle(color: AppColors.error)),
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
          return const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is empty',
            subtitle: 'Browse products and add items to your cart',
            actionLabel: 'Start Shopping',
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cart.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
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
            _CartBottomBar(
              totalAmount: cart.totalAmount,
              itemCount: cart.totalItems,
              onCheckout: () => context.push('/checkout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocalCart(BuildContext context, WidgetRef ref, LocalCart localCart) {
    if (localCart.isEmpty) {
      return const EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Your cart is empty',
        subtitle: 'Browse products and add items to your cart',
        actionLabel: 'Start Shopping',
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: localCart.items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final item = localCart.items[index];
              return _LocalCartItemTile(
                item: item,
                onQuantityChanged: (qty) {
                  ref.read(localCartProvider.notifier).updateQuantity(
                        item.productId,
                        qty,
                      );
                },
                onRemove: () {
                  ref.read(localCartProvider.notifier).removeItem(item.productId);
                },
              );
            },
          ),
        ),
        _CartBottomBar(
          totalAmount: localCart.totalAmount,
          itemCount: localCart.itemCount,
          onCheckout: () => context.push('/login'),
        ),
      ],
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
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
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
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemLayout({
    this.imageUrl,
    required this.name,
    required this.unitPrice,
    required this.subtotal,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                  price: unitPrice,
                  priceStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
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
  final int itemCount;
  final VoidCallback onCheckout;

  const _CartBottomBar({
    required this.totalAmount,
    required this.itemCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
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
                  Text(
                    Formatters.formatCurrency(totalAmount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.price,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text('Checkout ($itemCount)'),
            ),
          ],
        ),
      ),
    );
  }
}