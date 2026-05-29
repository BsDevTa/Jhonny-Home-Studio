import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/service_models.dart';
import '../data/services_api.dart';
import 'widgets/category_chip.dart';
import 'widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
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

    try {
      final results = await Future.wait([
        _servicesApi.getActiveCategories(),
        _servicesApi.getActiveServices(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = results[0] as List<ServiceCategoryModel>;
        _services = results[1] as List<ServiceModel>;
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() {
      _isLoading = true;
      _selectedCategoryId = categoryId;
      _errorMessage = null;
    });

    try {
      final services = categoryId == null
          ? await _servicesApi.getActiveServices()
          : await _servicesApi.getServicesByCategory(categoryId);

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
        _errorMessage = 'Não foi possível filtrar os serviços agora.';
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
          child: RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _loadInitialData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Text(
                  'Nossos serviços',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escolha a experiência ideal para o seu momento.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return CategoryChip(
                          label: 'Todos',
                          selected: _selectedCategoryId == null,
                          onTap: () => _filterByCategory(null),
                        );
                      }

                      final category = _categories[index - 1];
                      return CategoryChip(
                        label: category.name,
                        selected: _selectedCategoryId == category.id,
                        onTap: () => _filterByCategory(category.id),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemCount: _categories.length + 1,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  )
                else if (_errorMessage != null)
                  _EmptyState(
                    icon: Icons.error_outline,
                    title: 'Não foi possível carregar',
                    message: _errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _loadInitialData,
                  )
                else if (_services.isEmpty)
                  const _EmptyState(
                    icon: Icons.cut_outlined,
                    title: 'Nenhum serviço disponível',
                    message: 'Tente novamente em instantes.',
                  )
                else
                  ..._services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ServiceCard(
                        service: service,
                        onDetailsPressed: () => _openDetails(service),
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
