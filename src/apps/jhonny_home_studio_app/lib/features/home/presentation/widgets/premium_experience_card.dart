import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/premium_3d_button.dart';
import '../../../../shared/widgets/premium_gradient_border_card.dart';
import '../../../loyalty/data/loyalty_model.dart';

class PremiumExperienceCard extends StatelessWidget {
  const PremiumExperienceCard({
    super.key,
    required this.loyalty,
    required this.onVip,
    required this.onLoyalty,
    required this.onSos,
  });

  final LoyaltyModel loyalty;
  final VoidCallback onVip;
  final VoidCallback onLoyalty;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    return PremiumGradientBorderCard(
      subtleGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.diamond_outlined, color: AppColors.gold, size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Experiência Premium',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Benefícios exclusivos, cuidado personalizado e atendimento expresso quando você precisar.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExperienceLink(
                icon: Icons.workspace_premium_outlined,
                label: 'Clube VIP',
                onTap: onVip,
              ),
              _ExperienceLink(
                icon: Icons.loyalty_outlined,
                label: '${loyalty.level} · ${loyalty.points} pts',
                onTap: onLoyalty,
              ),
              _ExperienceLink(
                icon: Icons.auto_awesome_outlined,
                label: 'SOS Loiro',
                onTap: onSos,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Premium3dButton(
              text: 'Ver benefícios',
              icon: Icons.arrow_forward_rounded,
              onPressed: onLoyalty,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExperienceLink extends StatelessWidget {
  const _ExperienceLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.14),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
