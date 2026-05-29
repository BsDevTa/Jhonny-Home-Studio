import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/premium_icon_tile.dart';

class AppSideMenu extends StatelessWidget {
  const AppSideMenu({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const PremiumIconTile(icon: Icons.spa_rounded, size: 58),
            const SizedBox(height: 20),
            _SideIconButton(
              icon: Icons.home_rounded,
              label: 'Início',
              active: currentPath == AppRoutes.home,
              onTap: () => context.go(AppRoutes.home),
            ),
            _SideIconButton(
              icon: Icons.spa_rounded,
              label: 'Serviços',
              active: currentPath.startsWith('/services'),
              onTap: () => context.go(AppRoutes.services),
            ),
            _SideIconButton(
              icon: Icons.calendar_month_rounded,
              label: 'Agenda',
              active: currentPath.startsWith('/appointments'),
              onTap: () => context.go(AppRoutes.myAppointments),
            ),
            _SideIconButton(
              icon: Icons.person_rounded,
              label: 'Perfil',
              active:
                  currentPath == AppRoutes.profile ||
                  currentPath.startsWith('/addresses'),
              onTap: () => context.go(AppRoutes.profile),
            ),
            const Spacer(),
            _SideIconButton(
              icon: Icons.settings_rounded,
              label: 'Config',
              active: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Configurações serão implementadas em breve.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SideIconButton extends StatelessWidget {
  const _SideIconButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Material(
            color: active
                ? AppColors.gold.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onTap,
              icon: Icon(
                icon,
                color: active ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
