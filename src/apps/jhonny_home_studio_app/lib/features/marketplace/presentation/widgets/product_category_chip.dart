import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ProductCategoryChip extends StatelessWidget {
  const ProductCategoryChip({
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold.withValues(alpha: 0.18),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
      labelStyle: TextStyle(
        color: selected ? AppColors.goldLight : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
