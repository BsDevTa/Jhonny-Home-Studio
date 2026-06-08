import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/admin_mobile_api.dart';
import '../../presentation/admin_mobile_screens.dart';

AdminMobileApi _api(BuildContext context) =>
    AdminMobileApi(apiClient: context.read<ApiClient>());

String _text(Map<String, dynamic> item, String key) =>
    item[key]?.toString() ?? '';

bool _flag(Map<String, dynamic> item, String key, [bool fallback = false]) =>
    item[key] is bool ? item[key] as bool : fallback;

class AdminProductCategoryListScreen extends StatefulWidget {
  const AdminProductCategoryListScreen({super.key});

  @override
  State<AdminProductCategoryListScreen> createState() =>
      _AdminProductCategoryListScreenState();
}

class _AdminProductCategoryListScreenState
    extends State<AdminProductCategoryListScreen> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      categories = await _api(context).getMarketplaceCategories();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Categorias da Loja',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: () async {
          await context.push('/admin-mobile/marketplace/categories/new');
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Categorias de produto da loja',
              style: TextStyle(
                color: AppColors.champagne,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use categorias próprias do Marketplace, separadas das categorias de serviços.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            if (error.isNotEmpty)
              AdminMobileCard(
                child: Text(
                  error,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            if (!loading && categories.isEmpty)
              const AdminMobileCard(
                child: Text(
                  'Nenhuma categoria da loja cadastrada.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ...categories.map(
              (category) => AdminMobileCard(
                onTap: () async {
                  await context.push(
                    '/admin-mobile/marketplace/categories/${_text(category, 'id')}/edit',
                  );
                  _load();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(category, 'name'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_text(category, 'description')} · ordem ${_text(category, 'displayOrder')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: _flag(category, 'isActive')
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    PopupMenuButton<String>(
                      iconColor: AppColors.textSecondary,
                      onSelected: (action) async {
                        final api = _api(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final id = _text(category, 'id');
                        try {
                          if (action == 'toggle') {
                            await api.toggleMarketplaceCategory(id);
                          }
                          if (action == 'delete') {
                            await api.deleteMarketplaceCategory(id);
                          }
                          await _load();
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            _flag(category, 'isActive')
                                ? 'Desativar'
                                : 'Ativar',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
