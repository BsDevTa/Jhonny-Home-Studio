import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.textPrimary.withValues(alpha: 0.55),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      ),
    );
  }
}
