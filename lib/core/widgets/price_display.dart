import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PriceDisplay extends StatelessWidget {
  final double price;
  final double? discountedPrice;
  final double? discountPercentage;
  final TextStyle? priceStyle;
  final TextStyle? discountedPriceStyle;

  const PriceDisplay({
    super.key,
    required this.price,
    this.discountedPrice,
    this.discountPercentage,
    this.priceStyle,
    this.discountedPriceStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountedPrice != null && discountedPrice! < price;

    if (!hasDiscount) {
      return Text(
        'Rs. ${price.toStringAsFixed(price == price.round() ? 0 : 2)}',
        style: priceStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.price,
            ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rs. ${discountedPrice!.toStringAsFixed(discountedPrice! == discountedPrice!.round() ? 0 : 2)}',
          style: discountedPriceStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.priceDiscounted,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          'Rs. ${price.toStringAsFixed(price == price.round() ? 0 : 2)}',
          style: const TextStyle(
            fontSize: 13,
            decoration: TextDecoration.lineThrough,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
