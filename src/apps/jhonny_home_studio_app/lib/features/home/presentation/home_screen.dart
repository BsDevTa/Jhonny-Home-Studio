import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../../services/presentation/widgets/category_chip.dart';
import '../../services/presentation/widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ServicesApi _servicesApi;

  List<ServiceCategoryModel> _categories = const [];
  List<ServiceModel> _services = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _servicesApi = ServicesApi(apiClient: context.read<ApiClient>());
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.wait([
      _loadCategories(),
      _loadServices(updateSelectedCategory: false),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _servicesApi.getActiveCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
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
        _errorMessage = 'Não foi possível carregar as categorias agora.';
      });
    }
  }

  Future<void> _loadServices({
    String? categoryId,
    bool updateSelectedCategory = true,
  }) async {
    try {
      final services = categoryId == null
          ? await _servicesApi.getActiveServices()
          : await _servicesApi.getServicesByCategory(categoryId);

      if (!mounted) {
        return;
      }

      setState(() {
        _services = services;
        if (updateSelectedCategory) {
          _selectedCategoryId = categoryId;
        }
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
        _errorMessage = 'Não foi possível carregar os serviços agora.';
      });
    }
  }

  Future<void> _selectCategory(String? categoryId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCategoryId = categoryId;
    });

    await _loadServices(categoryId: categoryId, updateSelectedCategory: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _greeting(AuthProvider authProvider) {
    final userName = authProvider.user?.fullName.isNotEmpty == true
        ? authProvider.user!.fullName
        : AppTexts.welcome;
    return '$userName, seja bem-vindo(a)';
  }

  void _openServiceDetails(ServiceModel service) {
    context.push('/services/${service.id}');
  }

  void _openServicesScreen() {
    context.go(AppRoutes.services);
  }

  void _openCreateAppointment() {
    context.go(AppRoutes.services);
  }

  void _openMyAppointments() {
    context.go(AppRoutes.myAppointments);
  }

  void _openProfile() {
    context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final visibleServices = _services.take(4).toList(growable: false);
    final hasServices = visibleServices.isNotEmpty;

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
          child: RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                              _greeting(authProvider),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Categorias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: _isLoading && _categories.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return CategoryChip(
                                  label: 'Todos',
                                  selected: _selectedCategoryId == null,
                                  onTap: () => _selectCategory(null),
                                );
                              }

                              final category = _categories[index - 1];
                              return CategoryChip(
                                label: category.name,
                                selected: _selectedCategoryId == category.id,
                                onTap: () => _selectCategory(category.id),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemCount: _categories.length + 1,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Serviços',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: _openServicesScreen,
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading && _services.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    )
                  else if (_errorMessage != null && !hasServices)
                    _HomeMessage(
                      icon: Icons.error_outline,
                      title: 'Não foi possível carregar',
                      message: _errorMessage!,
                      actionLabel: 'Tentar novamente',
                      onAction: _loadInitialData,
                    )
                  else if (!hasServices)
                    const _HomeMessage(
                      icon: Icons.cut_outlined,
                      title: 'Nenhum serviço disponível',
                      message: 'No momento não há serviços ativos para exibir.',
                    )
                  else ...[
                    ...visibleServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ServiceCard(
                          service: service,
                          onDetailsPressed: () => _openServiceDetails(service),
                        ),
                      ),
                    ),
                    if (_services.length > visibleServices.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Mostrando ${visibleServices.length} de ${_services.length} serviços',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                  if (_errorMessage != null && hasServices) ...[
                    const SizedBox(height: 8),
                    _InlineNotice(message: _errorMessage!),
                  ],
                  const SizedBox(height: 26),
                  const Text(
                    'Atalhos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FeatureCard(
                    title: 'Agendar agora',
                    subtitle: 'Em breve você poderá reservar seu horário.',
                    icon: Icons.calendar_month_outlined,
                    onTap: _openCreateAppointment,
                  ),
                  const SizedBox(height: 14),
                  _FeatureCard(
                    title: 'Meus agendamentos',
                    subtitle: 'Acompanhe seus próximos atendimentos.',
                    icon: Icons.event_note_outlined,
                    onTap: _openMyAppointments,
                  ),
                  const SizedBox(height: 14),
                  _FeatureCard(
                    title: 'Perfil',
                    subtitle: 'Gerencie seus dados e preferências.',
                    icon: Icons.person_outline,
                    onTap: _openProfile,
                  ),
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
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.gold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
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

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
