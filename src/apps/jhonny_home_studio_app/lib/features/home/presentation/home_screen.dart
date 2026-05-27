import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../auth/presentation/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.fullName.isNotEmpty == true
        ? authProvider.user!.fullName
        : AppTexts.welcome;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              Color(0xFF101010),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(Icons.spa, color: AppColors.gold),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$userName, seja bem-vindo(a)',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppTexts.beautyBegins,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _FeatureCard(
                  title: 'Agendar agora',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 14),
                const _FeatureCard(title: 'Serviços', icon: Icons.star_outline),
                const SizedBox(height: 14),
                const _FeatureCard(
                  title: 'Meus agendamentos',
                  icon: Icons.event_note_outlined,
                ),
                const SizedBox(height: 14),
                const _FeatureCard(title: 'Perfil', icon: Icons.person_outline),
                const SizedBox(height: 24),
                PremiumButton(
                  text: AppTexts.logout,
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.circle, color: AppColors.gold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(icon, color: AppColors.quartz),
          ],
        ),
      ),
    );
  }
}
