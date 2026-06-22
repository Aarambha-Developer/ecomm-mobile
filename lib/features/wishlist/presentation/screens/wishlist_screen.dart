import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/widgets/empty_state.dart';
import 'package:aarambha_app/core/widgets/product_card.dart';
import 'package:aarambha_app/core/widgets/loading_widget.dart';
import 'package:aarambha_app/features/wishlist/presentation/providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          if (wishlistAsync.valueOrNull?.items.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(wishlistProvider.notifier).clearWishlist(),
            ),
        ],
      ),
      body: wishlistAsync.when(
          loading: () => const LoadingWidget(message: 'Loading wishlist...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load wishlist',
                  style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(wishlistProvider.notifier).loadWishlist(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (wishlist) {
          if (wishlist.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              subtitle: 'Save your favorite items to buy later',
              actionLabel: 'Browse Products',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: wishlist.items.length,
            itemBuilder: (context, index) {
              final item = wishlist.items[index];
              final product = item.product;
              return ProductCard(
                product: product,
                onTap: () => context.push('/products/${product.slug}'),
                isWishlisted: true,
                onToggleWishlist: () {
                  ref
                      .read(wishlistProvider.notifier)
                      .toggleItem(product.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
