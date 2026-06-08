import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/premium_section_header.dart';
import '../data/marketplace_api.dart';
import '../data/marketplace_models.dart';
import 'widgets/product_card.dart';
import 'widgets/product_category_chip.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final MarketplaceApi _api;
  final _searchController = TextEditingController();

  List<ProductCategoryModel> _categories = const [];
  List<ProductModel> _products = const [];
  bool _loading = true;
  String? _error;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _api = MarketplaceApi(apiClient: context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getCategories(),
        _api.getProducts(
          categoryId: _categoryId,
          search: _searchController.text,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<ProductCategoryModel>;
        _products = results[1] as List<ProductModel>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar a loja agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProduct(ProductModel product) {
    context.push('${AppRoutes.marketplace}/products/${product.id}');
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    if (width >= 420) return 2;
    return 1;
  }

  List<ProductModel> _dedupeById(Iterable<ProductModel> products) {
    final seen = <String>{};
    return [
      for (final product in products)
        if (seen.add(product.id)) product,
    ];
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
            onRefresh: _load,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                final childAspectRatio = _getChildAspectRatio(crossAxisCount);
                final imageHeight = _getImageHeight(crossAxisCount);
                final allProducts = _dedupeById(_products);
                final featuredProducts = allProducts
                    .where((product) => product.isFeatured)
                    .toList(growable: false);
                final featuredIds = featuredProducts
                    .map((product) => product.id)
                    .toSet();
                final regularProducts = allProducts
                    .where((product) => !featuredIds.contains(product.id))
                    .toList(growable: false);
                final emptyMessage = _categoryId == null
                    ? 'Nenhum produto disponível no momento.'
                    : 'Nenhum produto encontrado nesta categoria.';

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    const Text(
                      'LOJA - VOCÊ MAIS BEAUTIFUL.',
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Beleza premium também no cuidado diário.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Buscar produto',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ProductCategoryChip(
                              label: 'Todos',
                              selected: _categoryId == null,
                              onTap: () {
                                _categoryId = null;
                                _load();
                              },
                            );
                          }
                          final category = _categories[index - 1];
                          return ProductCategoryChip(
                            label: category.name,
                            selected: _categoryId == category.id,
                            onTap: () {
                              _categoryId = category.id;
                              _load();
                            },
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: _categories.length + 1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    else if (_error != null)
                      _Notice(message: _error!, onRetry: _load)
                    else if (allProducts.isEmpty)
                      _Notice(message: emptyMessage)
                    else ...[
                      if (featuredProducts.isNotEmpty) ...[
                        PremiumSectionHeader(
                          title: 'Destaques',
                          subtitle: 'Selecionados para sua rotina de beleza.',
                        ),
                        const SizedBox(height: 12),
                        _ProductGrid(
                          products: featuredProducts,
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          imageHeight: imageHeight,
                          onOpenProduct: _openProduct,
                        ),
                        const SizedBox(height: 22),
                      ],
                      if (regularProducts.isNotEmpty) ...[
                        PremiumSectionHeader(
                          title: 'Produtos',
                          subtitle: 'Escolha e finalize pelo WhatsApp.',
                        ),
                        const SizedBox(height: 12),
                        _ProductGrid(
                          products: regularProducts,
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          imageHeight: imageHeight,
                          onOpenProduct: _openProduct,
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getChildAspectRatio(int crossAxisCount) {
    return switch (crossAxisCount) {
      4 => 0.68,
      3 => 0.66,
      2 => 0.58,
      _ => 1.05,
    };
  }

  double _getImageHeight(int crossAxisCount) {
    return switch (crossAxisCount) {
      4 => 132,
      3 => 128,
      2 => 116,
      _ => 150,
    };
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.imageHeight,
    required this.onOpenProduct,
  });

  final List<ProductModel> products;
  final int crossAxisCount;
  final double childAspectRatio;
  final double imageHeight;
  final ValueChanged<ProductModel> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          imageHeight: imageHeight,
          onTap: () => onOpenProduct(product),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    );
  }
}
