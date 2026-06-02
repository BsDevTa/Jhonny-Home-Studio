import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onPressed == null ? 0.62 : 1,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.goldLight,
                AppColors.gold,
                AppColors.copper,
                AppColors.goldDark,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(1),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              disabledBackgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
              disabledForegroundColor: AppColors.background,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.background,
                      ),
                    )
                  : Text(text, key: const ValueKey('text')),
            ),
          ),
        ),
      ),
    );
  }
}
