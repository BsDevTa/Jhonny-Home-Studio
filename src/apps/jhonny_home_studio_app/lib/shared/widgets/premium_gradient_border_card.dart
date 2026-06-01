import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PremiumGradientBorderCard extends StatelessWidget {
  const PremiumGradientBorderCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.backgroundSoft,
    this.borderWidth = 0.9,
    this.subtleGlow = false,
    this.gradient = const LinearGradient(
      colors: [
        AppColors.goldDark,
        AppColors.champagne,
        AppColors.copper,
        AppColors.goldDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderWidth;
  final bool subtleGlow;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: subtleGlow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.10),
                  blurRadius: 16,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
