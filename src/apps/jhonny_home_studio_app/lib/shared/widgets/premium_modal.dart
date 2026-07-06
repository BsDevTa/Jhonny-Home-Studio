import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PremiumModal extends StatelessWidget {
  const PremiumModal({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxWidth = 560,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => PremiumModal(maxWidth: maxWidth, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderGold),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
