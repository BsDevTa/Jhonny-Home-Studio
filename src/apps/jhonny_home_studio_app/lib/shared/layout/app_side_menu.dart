import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/settings/presentation/app_settings_provider.dart';
import '../widgets/premium_icon_tile.dart';

class AppSideMenu extends StatelessWidget {
  const AppSideMenu({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>().settings;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                children: [
                  const PremiumIconTile(icon: Icons.spa_rounded, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.studioName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          settings.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _SideIconButton(
              icon: Icons.home_rounded,
              label: 'In\u00edcio',
              active: currentPath == AppRoutes.home,
              onTap: () => context.go(AppRoutes.home),
            ),
            _SideIconButton(
              icon: Icons.spa_rounded,
              label: 'Servi\u00e7os',
              active: currentPath.startsWith('/services'),
              onTap: () => context.go(AppRoutes.services),
            ),
            _SideIconButton(
              icon: Icons.storefront_rounded,
              label: 'Marketplace',
              active: currentPath.startsWith('/marketplace'),
              onTap: () => context.go(AppRoutes.marketplace),
            ),
            _SideIconButton(
              icon: Icons.calendar_month_rounded,
              label: 'Agenda',
              active: currentPath.startsWith('/appointments'),
              onTap: () => context.go(AppRoutes.myAppointments),
            ),
            _SideIconButton(
              icon: Icons.workspace_premium_rounded,
              label: 'Clube VIP',
              active: currentPath == AppRoutes.vip,
              onTap: () => context.go(AppRoutes.vip),
            ),
            _SideIconButton(
              icon: Icons.auto_awesome_rounded,
              label: 'SOS Loiro',
              active: currentPath == AppRoutes.sosLoiro,
              onTap: () => context.go(AppRoutes.sosLoiro),
            ),
            _SideIconButton(
              icon: Icons.person_rounded,
              label: 'Perfil',
              active:
                  currentPath == AppRoutes.profile ||
                  currentPath.startsWith('/addresses'),
              onTap: () => context.go(AppRoutes.profile),
            ),
            if (isAdmin)
              _SideIconButton(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin',
                active: currentPath.startsWith(AppRoutes.adminMobile),
                onTap: () => context.go(AppRoutes.adminMobile),
              ),
            const Spacer(),
            _SideIconButton(
              icon: Icons.settings_rounded,
              label: 'Configuracoes',
              active: currentPath == AppRoutes.clientSettings,
              onTap: () => context.go(AppRoutes.clientSettings),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: active
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? AppColors.gold : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
