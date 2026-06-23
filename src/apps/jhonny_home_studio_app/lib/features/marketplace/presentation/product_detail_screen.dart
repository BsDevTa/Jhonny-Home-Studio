import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../shared/widgets/premium_3d_button.dart';
import '../../settings/presentation/app_settings_provider.dart';
import '../data/marketplace_api.dart';
import '../data/marketplace_models.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final MarketplaceApi _api;
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  ProductModel? _product;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = MarketplaceApi(apiClient: context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    try {
      final product = await _api.getProductById(widget.productId);
      if (!mounted) return;
      setState(() => _product = product);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'NÃ£o foi possÃ­vel carregar o produto.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWhatsApp(ProductModel product) async {
    final settings = context.read<AppSettingsProvider>().settings;
    final messenger = ScaffoldMessenger.of(context);
    if (!hasConfiguredWhatsAppNumber(settings.whatsAppNumber)) {
      messenger.showSnackBar(
        const SnackBar(content: Text(whatsAppNotConfiguredMessage)),
      );
      return;
    }

    final opened = await openWhatsApp(
      phoneNumber: settings.whatsAppNumber,
      message:
          'Olá, tenho interesse em um produto da LOJA - VOCÊ MAIS BEAUTIFUL.\n\n'
          'Produto: ${product.name}\n'
          'Valor: ${_currency.format(product.currentPrice)}\n\n'
          'Gostaria de saber disponibilidade.',
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('NÃ£o foi possÃ­vel abrir o WhatsApp agora.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Produto')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
            : product == null
            ? Center(
                child: Text(
                  _error ?? 'Produto nÃ£o encontrado.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: product.hasImage
                          ? Image.network(
                              product.mainImageUrl,
                              fit: BoxFit.cover,
                            )
                          : const _DetailPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.productCategoryName,
                    style: const TextStyle(
                      color: AppColors.goldSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _currency.format(product.currentPrice),
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (product.hasPromotionalPrice) ...[
                        const SizedBox(width: 10),
                        Text(
                          _currency.format(product.price),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.isAvailable
                        ? 'DisponÃ­vel para consulta'
                        : 'Consulte disponibilidade',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Premium3dButton(
                    text: 'Comprar pelo WhatsApp',
                    icon: Icons.chat_outlined,
                    onPressed: () => _openWhatsApp(product),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(product),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Tenho interesse'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.goldDark,
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.champagne,
        size: 60,
      ),
    );
  }
}
