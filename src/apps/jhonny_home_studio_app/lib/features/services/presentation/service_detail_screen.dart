import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/service_presentation_formatter.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../data/service_models.dart';
import '../data/services_api.dart';
import 'widgets/service_image.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late final ServicesApi _servicesApi;

  ServiceModel? _service;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _servicesApi = ServicesApi(apiClient: context.read<ApiClient>());
    _loadService();
  }

  Future<void> _loadService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = await _servicesApi.getServiceById(widget.serviceId);
      if (!mounted) {
        return;
      }
      setState(() {
        _service = service;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Nao foi possivel carregar os detalhes do servico.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToCreateAppointment() {
    final serviceId = _service?.id;
    if (serviceId == null || serviceId.isEmpty) {
      return;
    }

    context.push('/appointments/create/$serviceId');
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                )
              : _errorMessage != null
              ? _DetailMessage(
                  icon: Icons.error_outline,
                  title: 'Detalhes indisponiveis',
                  message: _errorMessage!,
                  actionLabel: 'Tentar novamente',
                  onAction: _loadService,
                )
              : _service == null
              ? const _DetailMessage(
                  icon: Icons.cut_outlined,
                  title: 'Servico nao encontrado',
                  message: 'O servico solicitado nao esta disponivel.',
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PageHeader(
                            title: 'Detalhes do servico',
                            subtitle:
                                'Tudo o que importa, em uma leitura limpa e objetiva.',
                            onBack: () => context.pop(),
                          ),
                          const SizedBox(height: 12),
                          PremiumCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroImage(service: _service!),
                                const SizedBox(height: 12),
                                Text(
                                  _service!.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _MetaChip(
                                  icon: Icons.payments_outlined,
                                  label: ServicePresentationFormatter.priceFrom(
                                    _service!.price,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_service!.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            PremiumCard(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                _service!.description,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 48,
                            child: PremiumButton(
                              text: 'Agendar agora',
                              onPressed: _goToCreateAppointment,
                            ),
                          ),
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

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return ServiceImage(
      imageUrl: service.imageUrl,
      label: service.name,
      aspectRatio: 1.08,
      borderRadius: 18,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldSoft),
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
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_rounded, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PremiumEmptyState(
          icon: icon,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}
