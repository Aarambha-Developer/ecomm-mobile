import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DiscountBadge extends StatelessWidget {
  final double discountPercentage;

  const DiscountBadge({
    super.key,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    if (discountPercentage <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.discount,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        '${discountPercentage.round()}% Off',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
