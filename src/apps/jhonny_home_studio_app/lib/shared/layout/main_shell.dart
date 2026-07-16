import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../responsive/app_breakpoints.dart';
import '../widgets/premium_card.dart';
import 'app_bottom_nav.dart';
import 'app_drawer.dart';
import 'app_side_menu.dart';
import '../../features/settings/presentation/app_settings_provider.dart';
import 'package:provider/provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>().settings;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AppBreakpoints.isDesktopWidth(constraints.maxWidth);
        final showInsightPanel =
            currentPath == AppRoutes.home && constraints.maxWidth >= 1200;
        final content = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth(constraints.maxWidth),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 0),
              child: child,
            ),
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isDesktop ? null : AppDrawer(currentPath: currentPath),
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  settings.studioName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            leading: Builder(
              builder: (context) => isDesktop
                  ? const SizedBox(width: 24)
                  : IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      iconSize: 20,
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
            ),
            actions: [
              if (isDesktop)
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.marketplace),
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: const Text('Marketplace'),
                ),
              if (isDesktop) const SizedBox(width: 6),
              IconButton(
                onPressed: () => context.go(AppRoutes.createAppointment),
                iconSize: 20,
                icon: const Icon(Icons.calendar_month_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isDesktop
              ? Row(
                  children: [
                    AppSideMenu(currentPath: currentPath),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: content),
                          const _DesktopFooter(),
                        ],
                      ),
                    ),
                    if (showInsightPanel)
                      _DesktopInsightPanel(currentPath: currentPath),
                  ],
                )
              : content,
          bottomNavigationBar: isDesktop
              ? null
              : AppBottomNav(
                  currentPath: currentPath,
                  onHome: () => context.go(AppRoutes.home),
                  onServices: () => context.go(AppRoutes.services),
                  onAppointments: () => context.go(AppRoutes.myAppointments),
                  onProfile: () => context.go(AppRoutes.profile),
                ),
        );
      },
    );
  }
}

class _DesktopFooter extends StatelessWidget {
  const _DesktopFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.88),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
        ),
      ),
      child: const Text(
        'Johnny Home Studio | Sistema web premium',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DesktopInsightPanel extends StatelessWidget {
  const _DesktopInsightPanel({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 316,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        border: Border(
          left: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          children: [
            _PanelHeader(currentPath: currentPath),
            const SizedBox(height: 14),
            _PanelActionCard(
              icon: Icons.calendar_month_rounded,
              title: 'Agendamentos',
              subtitle: 'Veja seus horarios e acompanhe cada atendimento.',
              action: 'Abrir agenda',
              onTap: () => context.go(AppRoutes.myAppointments),
            ),
            const SizedBox(height: 12),
            _PanelActionCard(
              icon: Icons.spa_rounded,
              title: 'Ultimos servicos',
              subtitle: 'Retome os cuidados e escolha sua proxima experiencia.',
              action: 'Ver servicos',
              onTap: () => context.go(AppRoutes.services),
            ),
            const SizedBox(height: 12),
            _PanelActionCard(
              icon: Icons.storefront_rounded,
              title: 'Marketplace',
              subtitle: 'Produtos premium para continuar o ritual em casa.',
              action: 'Entrar na loja',
              onTap: () => context.go(AppRoutes.marketplace),
            ),
            const SizedBox(height: 12),
            _PanelActionCard(
              icon: Icons.workspace_premium_rounded,
              title: 'Clube VIP',
              subtitle: 'Nivel, beneficios e pontos sempre ao alcance.',
              action: 'Ver clube',
              onTap: () => context.go(AppRoutes.vip),
            ),
            const SizedBox(height: 18),
            const Text(
              'Johnny Home Studio',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final title = switch (currentPath) {
      String path when path.startsWith('/marketplace') => 'Loja premium',
      String path when path.startsWith('/appointments') => 'Sua agenda',
      String path when path == AppRoutes.vip => 'Clube VIP',
      String path when path == AppRoutes.sosLoiro => 'SOS Loiro',
      _ => 'Painel do cliente',
    };

    return PremiumCard(
      gradient: const LinearGradient(
        colors: [AppColors.surfaceElevated, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => context.go(AppRoutes.home),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.goldLight,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Atalhos essenciais para navegar pelo sistema desktop.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Abrir o dashboard do cliente.',
            style: TextStyle(
              color: AppColors.goldLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelActionCard extends StatelessWidget {
  const _PanelActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            action,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
