import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/responsive/app_breakpoints.dart';
import '../../../shared/widgets/premium_section_header.dart';
import '../data/marketplace_api.dart';
import '../data/marketplace_models.dart';
import 'widgets/product_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final MarketplaceApi _api;
  final _searchController = TextEditingController();

  List<ProductModel> _products = const [];
  bool _loading = true;
  String? _error;

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
      final products = await _api.getProducts(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _products = products;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel carregar a loja agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openProduct(ProductModel product) {
    context.push('${AppRoutes.marketplace}/products/${product.id}');
  }

  int _getCrossAxisCount(double width) {
    if (width >= 2000) return 6;
    if (width >= 1600) return 5;
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
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
                final isDesktop = AppBreakpoints.isDesktopWidth(
                  constraints.maxWidth,
                );
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

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20,
                    isDesktop ? 28 : 18,
                    isDesktop ? 32 : 20,
                    24,
                  ),
                  children: [
                    const Text(
                      'LOJA - VOCE MAIS BEAUTIFUL.',
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Beleza premium tambem no cuidado diario.',
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
                    const SizedBox(height: 18),
                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    else if (_error != null)
                      _Notice(message: _error!, onRetry: _load)
                    else if (allProducts.isEmpty)
                      const _Notice(message: 'Nenhum produto disponivel no momento.')
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
      6 => 0.70,
      5 => 0.69,
      4 => 0.68,
      3 => 0.66,
      _ => 0.58,
    };
  }

  double _getImageHeight(int crossAxisCount) {
    return switch (crossAxisCount) {
      6 => 126,
      5 => 130,
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
