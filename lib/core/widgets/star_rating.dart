import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final int starCount;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.starCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (starValue <= rating) {
          icon = Icons.star;
          color = AppColors.warning;
        } else if (starValue - rating <= 0.5) {
          icon = Icons.star_half;
          color = AppColors.warning;
        } else {
          icon = Icons.star_border;
          color = AppColors.textHint;
        }

        return Icon(icon, size: size, color: color);
      }),
    );
  }
}
