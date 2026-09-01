import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/responsive/app_breakpoints.dart';
import '../data/service_models.dart';
import '../data/services_api.dart';
import 'widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final ServicesApi _servicesApi;

  List<ServiceModel> _services = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _servicesApi = ServicesApi(apiClient: context.read<ApiClient>());
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final services = await _servicesApi.getActiveServices();
      if (!mounted) {
        return;
      }
      setState(() {
        _services = services;
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
        _errorMessage = 'Nao foi possivel carregar os servicos agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openDetails(ServiceModel service) {
    context.push('/services/${service.id}');
  }

  int _columnsFor(double width) {
    if (width >= 1400) {
      return 4;
    }
    if (width >= 1000) {
      return 3;
    }
    if (width >= 700) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = AppBreakpoints.horizontalPadding(screenWidth);
    final maxContentWidth = AppBreakpoints.maxContentWidth(screenWidth);

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
          child: RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _loadServices,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pagePadding, 16, pagePadding, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nossos servicos',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Escolha a experiencia ideal para o seu momento.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                              ),
                            ),
                          )
                        else if (_errorMessage != null)
                          _EmptyState(
                            icon: Icons.error_outline,
                            title: 'Nao foi possivel carregar',
                            message: _errorMessage!,
                            actionLabel: 'Tentar novamente',
                            onAction: _loadServices,
                          )
                        else if (_services.isEmpty)
                          const _EmptyState(
                            icon: Icons.cut_outlined,
                            title: 'Nenhum servico disponivel',
                            message: 'Tente novamente em instantes.',
                          )
                        else
                          _ServicesGrid(
                            services: _services,
                            columns: _columnsFor(screenWidth),
                            onOpenDetails: _openDetails,
                          ),
                      ],
                    ),
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

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.services,
    required this.columns,
    required this.onOpenDetails,
  });

  final List<ServiceModel> services;
  final int columns;
  final ValueChanged<ServiceModel> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 1 ? 0.78 : 0.72,
      ),
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          service: service,
          onDetailsPressed: () => onOpenDetails(service),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 40),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
