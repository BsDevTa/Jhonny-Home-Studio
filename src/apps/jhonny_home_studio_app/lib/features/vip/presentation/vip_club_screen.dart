import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../shared/widgets/premium_3d_button.dart';
import '../../../shared/widgets/premium_gradient_border_card.dart';
import '../../settings/presentation/app_settings_provider.dart';

class VipClubScreen extends StatefulWidget {
  const VipClubScreen({super.key});

  @override
  State<VipClubScreen> createState() => _VipClubScreenState();
}

class _VipClubScreenState extends State<VipClubScreen> {
  bool _isOpeningWhatsApp = false;

  Future<void> _openWhatsApp() async {
    final settings = context.read<AppSettingsProvider>().settings;
    if (!hasConfiguredWhatsAppNumber(settings.whatsAppNumber)) {
      _showMessage(whatsAppNotConfiguredMessage);
      return;
    }

    setState(() {
      _isOpeningWhatsApp = true;
    });

    final opened = await openWhatsApp(
      phoneNumber: settings.whatsAppNumber,
      message: 'Olá, quero saber mais sobre o Clube VIP do Jhonny Home Studio.',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isOpeningWhatsApp = false;
    });

    if (!opened) {
      _showMessage('NÃ£o foi possÃ­vel abrir o WhatsApp agora.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _PremiumPage(
        title: 'Clube VIP',
        subtitle: 'BenefÃ­cios exclusivos para clientes especiais.',
        children: [
          const _IntroCard(),
          const SizedBox(height: 16),
          for (final plan in _plans) ...[
            _VipPlanCard(plan: plan, onPressed: _openWhatsApp),
            const SizedBox(height: 12),
          ],
          Premium3dButton(
            text: 'Quero ser VIP',
            icon: Icons.workspace_premium_outlined,
            isLoading: _isOpeningWhatsApp,
            onPressed: _openWhatsApp,
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return const PremiumGradientBorderCard(
      subtleGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.diamond_outlined, color: AppColors.gold, size: 20),
          SizedBox(height: 10),
          Text(
            'Uma experiÃªncia alÃ©m do atendimento',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Prioridade, cuidado personalizado e acesso especial para tornar cada visita ainda mais exclusiva.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VipPlanCard extends StatelessWidget {
  const _VipPlanCard({required this.plan, required this.onPressed});

  final _VipPlan plan;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumGradientBorderCard(
      borderWidth: plan.highlighted ? 0.9 : 0.55,
      subtleGlow: plan.highlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (plan.highlighted)
                const Text(
                  'DESTAQUE',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            plan.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final benefit in plan.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onPressed,
              child: const Text('Quero ser VIP'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPage extends StatelessWidget {
  const _PremiumPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VipPlan {
  const _VipPlan({
    required this.name,
    required this.description,
    required this.benefits,
    this.highlighted = false,
  });

  final String name;
  final String description;
  final List<String> benefits;
  final bool highlighted;
}

const _plans = [
  _VipPlan(
    name: 'VIP Essential',
    description: 'Uma entrada elegante para benefÃ­cios exclusivos.',
    benefits: ['Acesso antecipado a novidades', 'ExperiÃªncia personalizada'],
  ),
  _VipPlan(
    name: 'VIP Gold',
    description: 'Mais prioridade para uma rotina beauty sem pressa.',
    benefits: [
      'Atendimento prioritÃ¡rio',
      'BenefÃ­cios em serviÃ§os premium',
      'Brindes exclusivos',
    ],
    highlighted: true,
  ),
  _VipPlan(
    name: 'VIP Diamond',
    description: 'O cuidado mais completo para clientes especiais.',
    benefits: [
      'HorÃ¡rios especiais',
      'Atendimento prioritÃ¡rio',
      'Acesso antecipado Ã  agenda',
      'ExperiÃªncia personalizada',
    ],
  ),
];
