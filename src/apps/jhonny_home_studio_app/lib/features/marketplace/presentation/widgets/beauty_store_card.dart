import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/premium_3d_button.dart';
import '../../../../shared/widgets/premium_gradient_border_card.dart';

class BeautyStoreCard extends StatelessWidget {
  const BeautyStoreCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PremiumGradientBorderCard(
      subtleGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.gold,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LOJA - VOCÊ MAIS BEAUTIFUL.',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Produtos premium para cuidar da sua beleza em casa.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Premium3dButton(
            text: 'Entrar na loja',
            icon: Icons.arrow_forward_rounded,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
