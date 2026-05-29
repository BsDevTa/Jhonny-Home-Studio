import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: selected
            ? AppColors.buttonSecondaryBackground.withValues(alpha: 0.72)
            : AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.copper.withValues(alpha: 0.36)
                    : AppColors.border.withValues(alpha: 0.75),
                width: 0.6,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.buttonSecondaryText
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
