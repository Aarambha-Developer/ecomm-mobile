import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

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
        Formatters.formatCurrency(price),
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
          Formatters.formatCurrency(discountedPrice!),
          style: discountedPriceStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.priceDiscounted,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          Formatters.formatCurrency(price),
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
