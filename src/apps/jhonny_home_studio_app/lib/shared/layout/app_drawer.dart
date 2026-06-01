import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/whatsapp_helper.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/settings/presentation/app_settings_provider.dart';
import '../widgets/premium_card.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>().settings;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: PremiumCard(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.surfaceElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.background.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.studioName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.person_outline,
                    title: 'Minha conta',
                    selected: currentPath == '/profile',
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.profile);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_outlined,
                    title: 'Meus endereços',
                    selected: currentPath.startsWith('/addresses'),
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.addresses);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.event_note_outlined,
                    title: 'Meus agendamentos',
                    selected: currentPath.startsWith('/appointments/my'),
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.myAppointments);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.spa_outlined,
                    title: 'Serviços',
                    selected: currentPath.startsWith('/services'),
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.services);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Agendar agora',
                    selected: currentPath.startsWith('/appointments/create'),
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.createAppointment);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Clube VIP',
                    selected: currentPath == AppRoutes.vip,
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.vip);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.loyalty_outlined,
                    title: 'Cartão fidelidade',
                    selected: currentPath == AppRoutes.loyalty,
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.loyalty);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'SOS Loiro',
                    selected: currentPath == AppRoutes.sosLoiro,
                    onTap: () {
                      context.pop();
                      context.go(AppRoutes.sosLoiro);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    onTap: () {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configurações serão implementadas em breve.',
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Ajuda / WhatsApp',
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final settings = context
                          .read<AppSettingsProvider>()
                          .settings;
                      context.pop();
                      if (settings.whatsAppNumber.trim().isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'WhatsApp do estúdio ainda não configurado.',
                            ),
                          ),
                        );
                        return;
                      }

                      final opened = await openWhatsApp(
                        phoneNumber: settings.whatsAppNumber,
                        message:
                            'Olá, preciso de ajuda com meu atendimento no ${settings.studioName}.',
                      );
                      if (!opened) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível abrir o WhatsApp agora.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          visualDensity: VisualDensity.compact,
          dense: true,
          leading: Icon(
            icon,
            color: selected ? AppColors.gold : AppColors.textSecondary,
            size: 18,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
