import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/premium_card.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  static const _quartz = Color(0xFFE8B7C8);
  static const _dangerSoft = Color(0xFF8F3F46);

  bool _appointmentReminders = true;
  bool _paymentUpdates = true;
  bool _vipPromotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceElevated,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Configura\u00e7\u00f5es',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Ajuste suas prefer\u00eancias de comunica\u00e7\u00e3o e conta.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsSection(
                        title: 'Notifica\u00e7\u00f5es',
                        icon: Icons.notifications_none_rounded,
                        children: [
                          _PremiumSwitchTile(
                            title: 'Lembretes de Agendamento',
                            subtitle:
                                'Receba avisos antes do seu hor\u00e1rio.',
                            value: _appointmentReminders,
                            onChanged: (value) {
                              setState(() => _appointmentReminders = value);
                            },
                          ),
                          _PremiumSwitchTile(
                            title: 'Atualiza\u00e7\u00f5es de Pagamento',
                            subtitle:
                                'Acompanhe confirma\u00e7\u00f5es e pend\u00eancias.',
                            value: _paymentUpdates,
                            onChanged: (value) {
                              setState(() => _paymentUpdates = value);
                            },
                          ),
                          _PremiumSwitchTile(
                            title: 'Promo\u00e7\u00f5es e Clube VIP',
                            subtitle:
                                'Novidades, benef\u00edcios e campanhas especiais.',
                            value: _vipPromotions,
                            onChanged: (value) {
                              setState(() => _vipPromotions = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SettingsSection(
                        title: 'Outros',
                        icon: Icons.tune_rounded,
                        children: [
                          _ActionTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Termos de Uso e Privacidade',
                            subtitle:
                                'Consulte as regras e pol\u00edticas do app.',
                            iconColor: _quartz,
                            onTap: () {},
                          ),
                          _ActionTile(
                            icon: Icons.delete_outline_rounded,
                            title: 'Excluir Conta',
                            subtitle:
                                'Solicite a remo\u00e7\u00e3o dos seus dados.',
                            iconColor: _dangerSoft,
                            textColor: AppColors.danger,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: const LinearGradient(
        colors: [AppColors.surface, AppColors.surfaceElevated],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 19),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.champagne,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _PremiumSwitchTile extends StatelessWidget {
  const _PremiumSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      value: value,
      activeThumbColor: AppColors.background,
      activeTrackColor: AppColors.gold,
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.surfaceSoft,
      onChanged: onChanged,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.textColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
