import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/widgets/loading_widget.dart';
import 'package:aarambha_app/core/widgets/error_view.dart';
import 'package:aarambha_app/core/widgets/product_card.dart';
import 'package:aarambha_app/core/widgets/price_display.dart';
import 'package:aarambha_app/core/widgets/star_rating.dart';
import 'package:aarambha_app/core/widgets/discount_badge.dart';
import 'package:aarambha_app/features/products/data/models/product.dart';
import 'package:aarambha_app/features/products/presentation/providers/product_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Scaffold(
          body: LoadingWidget(message: 'Loading product...'),
        ),
        error: (error, _) => Scaffold(
          body: ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(productDetailProvider(widget.slug)),
          ),
        ),
        data: (product) => _buildContent(product),
      ),
      bottomNavigationBar: productAsync.whenOrNull(
        data: (product) => product.inStock
            ? _BottomBar(
                price: product.discountedPrice > 0
                    ? product.discountedPrice
                    : product.price,
                originalPrice:
                    product.hasDiscount ? product.price : null,
                quantity: _quantity,
                onQuantityChanged: (q) => setState(() => _quantity = q),
                onAddToCart: () {
                  ref.read(cartProvider.notifier).addItem(
                        productId: product.id,
                        quantity: _quantity,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to cart')),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildContent(Product product) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: _ImageGallery(
              images: product.images,
              primaryImage: product.primaryImage,
              selectedIndex: _selectedImageIndex,
              onIndexChanged: (i) => setState(() => _selectedImageIndex = i),
              discountPercentage: product.discountPercentage,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductInfo(product: product),
                const SizedBox(height: 24),
                _TabbedContent(product: product),
                const SizedBox(height: 24),
                _RelatedProducts(
                  currentProductId: product.id,
                  categorySlug: product.categorySlug,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<dynamic> images;
  final String? primaryImage;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final double discountPercentage;

  const _ImageGallery({
    required this.images,
    this.primaryImage,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final allImages = <String>[];
    if (primaryImage != null) allImages.add(primaryImage!);
    for (final img in images) {
      final url = img is String
          ? img
          : (img is Map ? img['image']?.toString() : null);
      if (url != null && url != primaryImage) {
        allImages.add(url);
      }
    }

    if (allImages.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 64, color: AppColors.textHint),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: allImages.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: allImages[index],
              fit: BoxFit.contain,
              placeholder: (_, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, _, _) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image, size: 64),
              ),
            );
          },
        ),
        if (allImages.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == selectedIndex ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.primary
                        : AppColors.textHint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        if (discountPercentage > 0)
          Positioned(
            top: 16,
            left: 16,
            child: DiscountBadge(discountPercentage: discountPercentage),
          ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;

  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (product.categoryName != null)
              _InfoChip(label: product.categoryName!),
            if (product.brandName != null) ...[
              const SizedBox(width: 8),
              _InfoChip(label: product.brandName!),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        PriceDisplay(
          price: product.price,
          discountedPrice:
              product.hasDiscount ? product.discountedPrice : null,
          discountPercentage: product.discountPercentage,
          priceStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.price,
          ),
          discountedPriceStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.priceDiscounted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            StarRating(rating: product.rating),
            const SizedBox(width: 8),
            Text(
              product.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              product.inStock
                  ? 'In stock (${product.stockQuantity} available)'
                  : 'Out of stock',
              style: TextStyle(
                color: product.inStock
                    ? AppColors.success
                    : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (product.description != null && product.description!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            product.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TabbedContent extends StatelessWidget {
  final Product product;

  const _TabbedContent({required this.product});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Description'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    product.description ?? 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Center(
                  child: Text(
                    'No reviews yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedProducts extends ConsumerWidget {
  final String currentProductId;
  final String? categorySlug;

  const _RelatedProducts({
    required this.currentProductId,
    this.categorySlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categorySlug == null) return const SizedBox.shrink();

    final relatedProducts = ref.watch(productListProvider);
    final related = relatedProducts.products
        .where((p) => p.id != currentProductId)
        .take(6)
        .toList();

    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You might also like',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final product = related[index];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: product,
                  onTap: () => context.push('/products/${product.slug}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.price,
    this.originalPrice,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onTap: quantity > 1
                        ? () => onQuantityChanged(quantity - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onTap: () => onQuantityChanged(quantity + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAddToCart,
                child: Text(
                  'Add to Cart · Rs. ${(price * quantity).toStringAsFixed(price == price.round() ? 0 : 2)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.transparent,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textHint,
        ),
      ),
    );
  }
}
