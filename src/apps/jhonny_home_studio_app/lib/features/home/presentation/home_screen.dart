import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/responsive/app_breakpoints.dart';
import '../../../shared/widgets/premium_dashboard_card.dart';
import '../../../shared/widgets/premium_modal.dart';
import '../../../shared/widgets/premium_section_header.dart';
import '../../loyalty/data/loyalty_api.dart';
import '../../loyalty/data/loyalty_model.dart';
import '../../marketplace/presentation/widgets/beauty_store_card.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../../services/presentation/widgets/service_story_item.dart';
import '../../stories/data/stories_api.dart';
import '../../stories/data/story_model.dart';
import '../../stories/presentation/story_viewer_screen.dart';
import '../../stories/presentation/widgets/story_circle_item.dart';
import '../../settings/presentation/app_settings_provider.dart';
import 'widgets/premium_experience_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showAdminRestrictedMessage = false});

  final bool showAdminRestrictedMessage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ServicesApi _servicesApi;
  late final StoriesApi _storiesApi;
  late final LoyaltyApi _loyaltyApi;

  List<ServiceModel> _services = const [];
  List<StoryModel> _editorialStories = const [];
  LoyaltyModel _loyalty = LoyaltyModel.empty;
  bool _isLoadingStories = true;
  bool _isLoadingServices = true;
  bool _isLoadingHomeData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _servicesApi = ServicesApi(apiClient: context.read<ApiClient>());
    _storiesApi = StoriesApi(apiClient: context.read<ApiClient>());
    _loyaltyApi = LoyaltyApi(apiClient: context.read<ApiClient>());
    if (widget.showAdminRestrictedMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acesso restrito ao administrador.')),
        );
      });
    }
    _loadHomeData();
  }

  Future<void> _loadHomeData({bool refreshSettings = false}) async {
    if (_isLoadingHomeData) {
      return;
    }

    debugPrint('Carregando Home...');
    setState(() {
      _isLoadingHomeData = true;
      _isLoadingStories = true;
      _isLoadingServices = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadServices(),
        _loadEditorialStories(),
        _loadLoyalty(),
        if (refreshSettings) context.read<AppSettingsProvider>().loadSettings(),
      ]);

      debugPrint('Home carregada com sucesso');
    } catch (error) {
      debugPrint('Erro ao carregar Home: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHomeData = false;
          _isLoadingStories = false;
          _isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _loadLoyalty() async {
    try {
      final loyalty = await _loyaltyApi.getMyLoyalty();
      if (mounted) {
        setState(() {
          _loyalty = loyalty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loyalty = LoyaltyModel.empty;
        });
      }
    }
  }

  Future<void> _loadEditorialStories() async {
    try {
      final stories = await _storiesApi.getActiveStories();
      if (!mounted) {
        return;
      }

      debugPrint('Stories carregados: ${stories.length}');
      for (final story in stories) {
        debugPrint('Story ${story.title} | imageUrl=${story.imageUrl}');
      }
      setState(() {
        _editorialStories = stories.take(8).toList(growable: false);
      });
    } catch (error) {
      debugPrint('Erro ao carregar Home: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _editorialStories = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  Future<void> _loadServices() async {
    try {
      final services = await _servicesApi.getActiveServices();

      if (!mounted) {
        return;
      }

      debugPrint('Serviços carregados: ${services.length}');
      setState(() {
        _services = services;
      });
    } on ApiException catch (error) {
      debugPrint('Erro ao carregar Home: ${error.message}');
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      debugPrint('Erro ao carregar Home: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Não foi possível carregar os serviços agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  void _openServiceDetails(ServiceModel service) {
    context.push('${AppRoutes.services}/${service.id}');
  }

  void _openServicesScreen() {
    context.go(AppRoutes.services);
  }

  void _openEditorialStory(StoryModel story) {
    if (AppBreakpoints.isDesktop(context)) {
      PremiumModal.show<void>(
        context: context,
        maxWidth: 460,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: StoryViewerScreen(story: story),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryViewerScreen(story: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>().settings;
    final visibleServices = _services.take(8).toList(growable: false);
    final hasServices = visibleServices.isNotEmpty;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(context);
    final pagePadding = AppBreakpoints.horizontalPadding(screenWidth);

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
            onRefresh: () => _loadHomeData(refreshSettings: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                pagePadding,
                isDesktop ? 28 : 18,
                pagePadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        settings.welcomeTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        settings.welcomeMessage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(height: 22),
                        _DesktopDashboardStrip(
                          serviceCount: _services.length,
                          loyalty: _loyalty,
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_isLoadingStories ||
                          _editorialStories.isNotEmpty) ...[
                        const Text(
                          'Destaques',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Novidades escolhidas para você.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(height: 88, child: _buildEditorialStories()),
                        const SizedBox(height: 24),
                      ],
                      PremiumSectionHeader(
                        title: 'Serviços',
                        subtitle:
                            'Experiências selecionadas para o seu momento.',
                        actionLabel: 'Ver todos',
                        onAction: _openServicesScreen,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 96,
                        child: _buildStories(visibleServices, hasServices),
                      ),
                      if (_errorMessage != null && hasServices) ...[
                        const SizedBox(height: 8),
                        _InlineNotice(message: _errorMessage!),
                      ],
                      const SizedBox(height: 22),
                      PremiumExperienceCard(
                        loyalty: _loyalty,
                        onVip: () => context.push(AppRoutes.vip),
                        onLoyalty: () => context.push(AppRoutes.loyalty),
                        onSos: () => context.push(AppRoutes.sosLoiro),
                      ),
                      const SizedBox(height: 14),
                      BeautyStoreCard(
                        onOpen: () => context.push(AppRoutes.marketplace),
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

  Widget _buildEditorialStories() {
    if (_isLoadingStories && _editorialStories.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => const StoryCircleSkeleton(),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: 6,
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        final story = _editorialStories[index];
        return StoryCircleItem(
          title: story.title,
          imageUrl: story.visualUrl,
          onTap: () => _openEditorialStory(story),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemCount: _editorialStories.length,
    );
  }

  Widget _buildStories(List<ServiceModel> visibleServices, bool hasServices) {
    if (_isLoadingServices && _services.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => const ServiceStorySkeleton(),
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemCount: 6,
      );
    }

    if (_errorMessage != null && !hasServices) {
      return _ServiceStoriesMessage(
        message: _errorMessage!,
        onRetry: _loadHomeData,
      );
    }

    if (!hasServices) {
      return const _ServiceStoriesMessage(
        message: 'Nenhum serviço disponível no momento.',
      );
    }

    return ListView.separated(
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
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemCount: visibleServices.length,
    );
  }

}

class _DesktopDashboardStrip extends StatelessWidget {
  const _DesktopDashboardStrip({
    required this.serviceCount,
    required this.loyalty,
  });

  final int serviceCount;
  final LoyaltyModel loyalty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth.clamp(190, 260).toDouble(),
              child: PremiumDashboardCard(
                icon: Icons.calendar_month_rounded,
                title: 'Agendamentos',
                value: 'Sua agenda',
                subtitle: 'Acompanhe horarios e detalhes.',
                onTap: () => context.go(AppRoutes.myAppointments),
              ),
            ),
            SizedBox(
              width: itemWidth.clamp(190, 260).toDouble(),
              child: PremiumDashboardCard(
                icon: Icons.spa_rounded,
                title: 'Ultimos servicos',
                value: '$serviceCount opcoes',
                subtitle: 'Continue sua experiencia.',
                onTap: () => context.go(AppRoutes.services),
              ),
            ),
            SizedBox(
              width: itemWidth.clamp(190, 260).toDouble(),
              child: PremiumDashboardCard(
                icon: Icons.shopping_bag_rounded,
                title: 'Marketplace',
                value: 'Loja premium',
                subtitle: 'Produtos para o cuidado diario.',
                onTap: () => context.go(AppRoutes.marketplace),
              ),
            ),
            SizedBox(
              width: itemWidth.clamp(190, 260).toDouble(),
              child: PremiumDashboardCard(
                icon: Icons.workspace_premium_rounded,
                title: 'Clube VIP',
                value: loyalty.level,
                subtitle: '${loyalty.points} pontos disponiveis.',
                onTap: () => context.go(AppRoutes.vip),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceStoriesMessage extends StatelessWidget {
  const _ServiceStoriesMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
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
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
