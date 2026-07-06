import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';

class PremiumNavbar extends StatelessWidget {
  const PremiumNavbar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Marketplace',
            child: IconButton(
              onPressed: () => context.go(AppRoutes.marketplace),
              icon: const Icon(Icons.shopping_bag_rounded),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Novo agendamento',
            child: FilledButton.icon(
              onPressed: () => context.go(AppRoutes.createAppointment),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('Agendar'),
            ),
          ),
        ],
      ),
    );
  }
}
