import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../features/products/data/models/product.dart';
import 'discount_badge.dart';
import 'price_display.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleWishlist;
  final bool isWishlisted;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.isWishlisted = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
child: Container(
          height: 290,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(product),
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: DiscountBadge(
                          discountPercentage: product.discountPercentage,
                        ),
                      ),
                    if (widget.onToggleWishlist != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: AppColors.white,
                          elevation: 0,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.onToggleWishlist,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                widget.isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.isWishlisted
                                    ? AppColors.accent
                                    : AppColors.textHint,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (product.stockQuantity == 0)
                      Positioned.fill(
                        child: Container(
                          color: AppColors.overlay,
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brandName != null)
                        Text(
                          product.brandName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      PriceDisplay(
                        price: product.price,
                        discountedPrice: product.discountedPrice,
                        discountPercentage: product.discountPercentage,
                        priceStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.price,
                        ),
                        discountedPriceStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.priceDiscounted,
                        ),
                      ),
                      const Spacer(),
                      if (widget.onAddToCart != null && product.stockQuantity > 0)
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: widget.onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Add to Cart'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Product product) {
    final imageUrl = product.primaryImage ?? product.images.firstOrNull?.image;
    if (imageUrl == null) {
      return Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 32),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.primaryLight),
      errorWidget: (_, _, _) => Container(
        color: AppColors.primaryLight,
        child:
            const Icon(Icons.broken_image_outlined, color: AppColors.textHint, size: 32),
      ),
    );
  }
}
