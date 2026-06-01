import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/appointment_status_helper.dart';

class PremiumStatusBadge extends StatelessWidget {
  const PremiumStatusBadge({super.key, required this.status});

  final String status;

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();

    return switch (normalized) {
      'pending' => AppColors.gold,
      'waitingpayment' => AppColors.champagne,
      'confirmed' => AppColors.success,
      'completed' => AppColors.copper,
      'canceled' => AppColors.error,
      'rejected' => AppColors.error,
      'noshow' => AppColors.error,
      'inprogress' => AppColors.goldSoft,
      'ontheway' => AppColors.gold,
      'rescheduled' => AppColors.champagne,
      _ => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = appointmentStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
