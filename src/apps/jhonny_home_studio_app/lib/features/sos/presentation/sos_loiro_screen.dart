import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../shared/widgets/premium_3d_button.dart';
import '../../../shared/widgets/premium_gradient_border_card.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../../settings/presentation/app_settings_provider.dart';

class SosLoiroScreen extends StatefulWidget {
  const SosLoiroScreen({super.key});

  @override
  State<SosLoiroScreen> createState() => _SosLoiroScreenState();
}

class _SosLoiroScreenState extends State<SosLoiroScreen> {
  late final ServicesApi _servicesApi;
  ServiceModel? _mechasService;
  String _selectedReason = _reasons.first;
  bool _isOpeningWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _servicesApi = ServicesApi(apiClient: context.read<ApiClient>());
    _loadMechasService();
  }

  Future<void> _loadMechasService() async {
    try {
      final services = await _servicesApi.getActiveServices();
      if (!mounted) {
        return;
      }

      for (final service in services) {
        if (service.name.toLowerCase().contains('mecha')) {
          setState(() {
            _mechasService = service;
          });
          return;
        }
      }
    } catch (_) {
      // A tela continua útil mesmo quando o catálogo está indisponível.
    }
  }

  Future<void> _openWhatsApp() async {
    final settings = context.read<AppSettingsProvider>().settings;
    if (settings.whatsAppNumber.trim().isEmpty) {
      _showMessage('WhatsApp do estúdio ainda não configurado.');
      return;
    }

    setState(() {
      _isOpeningWhatsApp = true;
    });

    final opened = await openWhatsApp(
      phoneNumber: settings.whatsAppNumber,
      message:
          '''
Olá, preciso de um SOS Loiro / Johnny Help.

Motivo: $_selectedReason

Quero saber disponibilidade para mechas ou correção premium.''',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isOpeningWhatsApp = false;
    });

    if (!opened) {
      _showMessage('Não foi possível abrir o WhatsApp agora.');
    }
  }

  void _openMechasService() {
    final service = _mechasService;
    context.go(
      service == null ? AppRoutes.services : '/services/${service.id}',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'SOS Loiro',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Johnny Help para mechas, correções e eventos.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const PremiumGradientBorderCard(
                      subtleGlow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Atendimento expresso premium',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Correção urgente, casamento, evento ou emergência estética? Conte com um atendimento expresso para transformar seu visual.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Mechas a partir de R\$ 599,90',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Como podemos ajudar?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasons
                          .map(
                            (reason) => ChoiceChip(
                              label: Text(reason),
                              selected: _selectedReason == reason,
                              onSelected: (_) {
                                setState(() {
                                  _selectedReason = reason;
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 18),
                    Premium3dButton(
                      text: 'Quero atendimento expresso',
                      icon: Icons.support_agent_outlined,
                      isLoading: _isOpeningWhatsApp,
                      onPressed: _openWhatsApp,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _openMechasService,
                      icon: const Icon(Icons.spa_outlined, size: 17),
                      label: const Text('Ver serviço de Mechas'),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('Falar no WhatsApp'),
                    ),
                    const SizedBox(height: 22),
                    const _PortfolioPlaceholder(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: const Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfólio de Mechas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Em breve, uma seleção de transformações para inspirar seu próximo visual.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _reasons = [
  'Correção urgente',
  'Evento',
  'Casamento',
  'Emergência estética',
  'Quero fazer mechas',
];
