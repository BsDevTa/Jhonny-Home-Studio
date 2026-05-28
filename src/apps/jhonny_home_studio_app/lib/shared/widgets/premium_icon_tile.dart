import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PremiumIconTile extends StatelessWidget {
  const PremiumIconTile({
    super.key,
    required this.icon,
    this.label,
    this.size = 42,
  });

  final IconData icon;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.16),
          width: 0.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: label == null
            ? Icon(icon, color: AppColors.gold, size: size * 0.44)
            : Text(
                label!,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
