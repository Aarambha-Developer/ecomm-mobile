import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory StatusBadge.orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusBadge(label: 'Pending', color: AppColors.statusPending);
      case 'confirmed':
        return StatusBadge(label: 'Confirmed', color: AppColors.statusConfirmed);
      case 'shipped':
        return StatusBadge(label: 'Shipped', color: AppColors.statusShipped);
      case 'delivered':
        return StatusBadge(label: 'Delivered', color: AppColors.statusDelivered);
      default:
        return StatusBadge(label: status, color: AppColors.secondary);
    }
  }

  factory StatusBadge.paymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return StatusBadge(label: 'Pending', color: AppColors.statusPending);
      case 'completed':
        return StatusBadge(label: 'Completed', color: AppColors.statusConfirmed);
      case 'failed':
        return StatusBadge(label: 'Failed', color: AppColors.statusFailed);
      default:
        return StatusBadge(label: status, color: AppColors.secondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
