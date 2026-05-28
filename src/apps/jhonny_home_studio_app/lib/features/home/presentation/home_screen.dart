import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../../services/presentation/widgets/category_chip.dart';
import '../../services/presentation/widgets/service_story_item.dart';
import '../../../shared/widgets/premium_action_card.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_icon_tile.dart';
import '../../../shared/widgets/premium_section_header.dart';

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
    context.go(AppRoutes.createAppointment);
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
    final visibleServices = _services.take(8).toList(growable: false);
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumCard(
                        padding: const EdgeInsets.all(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF18120B), Color(0xFF111111)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Row(
                          children: [
                            const PremiumIconTile(icon: Icons.spa_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(authProvider),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    AppTexts.beautyBegins,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      PremiumActionCard(
                        title: 'Agendar agora',
                        subtitle:
                            'Reserve seu horário com uma jornada mais delicada e clara.',
                        icon: Icons.calendar_month_rounded,
                        onTap: _openCreateAppointment,
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PremiumActionCard(
                        title: 'Próximo agendamento',
                        subtitle:
                            'Acompanhe sua agenda sem excesso de peso visual.',
                        icon: Icons.event_note_rounded,
                        onTap: _openMyAppointments,
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PremiumActionCard(
                        title: 'Meu perfil',
                        subtitle:
                            'Atualize seus dados em um espaço mais leve e refinado.',
                        icon: Icons.person_rounded,
                        onTap: _openProfile,
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.gold,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const PremiumSectionHeader(
                        title: 'Categorias',
                        subtitle: 'Escolha o estilo ideal para seu momento.',
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: _isLoading && _categories.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gold,
                                  strokeWidth: 2,
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
                                    selected:
                                        _selectedCategoryId == category.id,
                                    onTap: () => _selectCategory(category.id),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemCount: _categories.length + 1,
                              ),
                      ),
                      const SizedBox(height: 20),
                      PremiumSectionHeader(
                        title: 'Serviços',
                        subtitle:
                            'Experiências selecionadas para o seu momento.',
                        actionLabel: 'Ver todos',
                        onAction: _openServicesScreen,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 104,
                        child: _isLoading && _services.isEmpty
                            ? ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) =>
                                    const ServiceStorySkeleton(),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 14),
                                itemCount: 6,
                              )
                            : _errorMessage != null && !hasServices
                            ? _ServiceStoriesMessage(
                                title: 'Não foi possível carregar',
                                message: _errorMessage!,
                                onRetry: _loadInitialData,
                              )
                            : !hasServices
                            ? const _ServiceStoriesMessage(
                                title: 'Nenhum serviço disponível',
                                message:
                                    'Nenhum serviço disponível no momento.',
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  final service = visibleServices[index];
                                  return ServiceStoryItem(
                                    title: service.name,
                                    imageUrl: service.imageUrl,
                                    icon: Icons.spa_rounded,
                                    onTap: () => _openServiceDetails(service),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 12),
                                itemCount: visibleServices.length,
                              ),
                      ),
                      if (_errorMessage != null && hasServices) ...[
                        const SizedBox(height: 8),
                        _InlineNotice(message: _errorMessage!),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Atalhos',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        title: 'Agendar agora',
                        subtitle: 'Em breve você poderá reservar seu horário.',
                        icon: Icons.calendar_month_outlined,
                        onTap: _openCreateAppointment,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        title: 'Meus agendamentos',
                        subtitle: 'Acompanhe seus próximos atendimentos.',
                        icon: Icons.event_note_outlined,
                        onTap: _openMyAppointments,
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        title: 'Perfil',
                        subtitle: 'Gerencie seus dados e preferências.',
                        icon: Icons.person_outline,
                        onTap: _openProfile,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceStoriesMessage extends StatelessWidget {
  const _ServiceStoriesMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  width: 0.6,
                ),
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 18,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Tentar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    width: 0.6,
                  ),
                ),
                child: Icon(icon, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
          ),
        ),
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
