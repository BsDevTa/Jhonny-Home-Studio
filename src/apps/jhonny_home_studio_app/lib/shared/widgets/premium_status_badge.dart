import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PremiumStatusBadge extends StatelessWidget {
  const PremiumStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'pending' => AppColors.gold,
      'waitingpayment' => AppColors.quartz,
      'confirmed' => AppColors.success,
      'completed' => AppColors.copper,
      'canceled' => AppColors.error,
      'rejected' => AppColors.error,
      'noshow' => AppColors.error,
      'inprogress' => AppColors.goldSoft,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
