import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/premium_section_header.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../../services/presentation/widgets/category_chip.dart';
import '../../services/presentation/widgets/service_story_item.dart';

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

  void _openServiceDetails(ServiceModel service) {
    context.push('${AppRoutes.services}/${service.id}');
  }

  void _openServicesScreen() {
    context.go(AppRoutes.services);
  }

  @override
  Widget build(BuildContext context) {
    final visibleServices = _services.take(8).toList(growable: false);
    final hasServices = visibleServices.isNotEmpty;

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
            onRefresh: _loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const Text(
                        'Categorias',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(height: 34, child: _buildCategories()),
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

  Widget _buildStories(List<ServiceModel> visibleServices, bool hasServices) {
    if (_isLoading && _services.isEmpty) {
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
        onRetry: _loadInitialData,
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

  Widget _buildCategories() {
    if (_isLoading && _categories.isEmpty) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => const _CategorySkeleton(),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: 4,
      );
    }

    return ListView.separated(
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
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemCount: _categories.length + 1,
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

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
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
