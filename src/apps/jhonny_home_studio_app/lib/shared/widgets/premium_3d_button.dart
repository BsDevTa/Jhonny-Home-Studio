import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class Premium3dButton extends StatelessWidget {
  const Premium3dButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.goldDark, AppColors.champagne, AppColors.copper],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.44),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(0.8),
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: AppColors.goldLight,
                  ),
                )
              : Icon(icon ?? Icons.arrow_forward_rounded, size: 16),
          label: Text(text),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            backgroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.surface,
            foregroundColor: AppColors.goldLight,
            disabledForegroundColor: AppColors.goldLight,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
