import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../data/admin_mobile_api.dart';
import 'admin_mobile_screens.dart';

AdminMobileApi _api(BuildContext context) =>
    AdminMobileApi(apiClient: context.read<ApiClient>());

String _text(Map<String, dynamic> item, String key) =>
    item[key]?.toString() ?? '';
bool _flag(Map<String, dynamic> item, String key) =>
    item[key] is bool ? item[key] as bool : false;

class AdminMarketplaceProductListScreen extends StatefulWidget {
  const AdminMarketplaceProductListScreen({super.key});

  @override
  State<AdminMarketplaceProductListScreen> createState() =>
      _AdminMarketplaceProductListScreenState();
}

class _AdminMarketplaceProductListScreenState
    extends State<AdminMarketplaceProductListScreen> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> products = [];

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
      products = await _api(context).getMarketplaceProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Produtos da Loja',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: () async {
          await context.push('/admin-mobile/marketplace/products/new');
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo produto'),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            if (!loading && products.isEmpty)
              const AdminMobileCard(
                child: Text(
                  'Nenhum produto cadastrado.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ...products.map(
              (product) => AdminMobileCard(
                onTap: () async {
                  await context.push(
                    '/admin-mobile/marketplace/products/${_text(product, 'id')}/edit',
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
                            _text(product, 'name'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_text(product, 'productCategoryName')} · R\$ ${_text(product, 'price')}',
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
                      color: _flag(product, 'isActive')
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    PopupMenuButton<String>(
                      iconColor: AppColors.textSecondary,
                      onSelected: (action) async {
                        final api = _api(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final id = _text(product, 'id');
                        try {
                          if (action == 'toggle') {
                            await api.toggleMarketplaceProduct(id);
                          }
                          if (action == 'delete') {
                            await api.deleteMarketplaceProduct(id);
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
                            _flag(product, 'isActive') ? 'Desativar' : 'Ativar',
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

class AdminMarketplaceProductFormScreen extends StatefulWidget {
  const AdminMarketplaceProductFormScreen({super.key, this.id});

  final String? id;

  @override
  State<AdminMarketplaceProductFormScreen> createState() =>
      _AdminMarketplaceProductFormScreenState();
}

class _AdminMarketplaceProductFormScreenState
    extends State<AdminMarketplaceProductFormScreen> {
  final name = TextEditingController();
  final shortDescription = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final promotionalPrice = TextEditingController();
  final imageUrl = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  String categoryId = '';
  String categoriesError = '';
  bool active = true;
  bool featured = false;
  bool loadingCategories = true;
  bool saving = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    await _loadCategories(api);
    if (widget.id != null) {
      try {
        final product = await api.getMarketplaceProduct(widget.id!);
        name.text = _text(product, 'name');
        shortDescription.text = _text(product, 'shortDescription');
        description.text = _text(product, 'description');
        price.text = _text(product, 'price');
        promotionalPrice.text = _text(product, 'promotionalPrice');
        imageUrl.text = _text(product, 'mainImageUrl');
        categoryId = _text(product, 'productCategoryId');
        active = _flag(product, 'isActive');
        featured = _flag(product, 'isFeatured');
      } catch (error) {
        if (!mounted) return;
        _showMessage(_readApiError(error));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCategories(AdminMobileApi api) async {
    debugPrint('Carregando categorias marketplace...');
    if (mounted) {
      setState(() {
        loadingCategories = true;
        categoriesError = '';
      });
    }
    try {
      final loadedCategories = await api.getMarketplaceCategories();
      debugPrint('Categorias carregadas: ${loadedCategories.length}');
      if (!mounted) return;
      setState(() {
        categories = loadedCategories;
        categoriesError = '';
      });
    } catch (error) {
      debugPrint('Erro ao carregar categorias: $error');
      if (!mounted) return;
      setState(() {
        categories = [];
        categoriesError = _readApiError(
          error,
          fallback: 'Nao foi possivel carregar as categorias.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => loadingCategories = false);
      }
    }
  }

  Future<void> _createCategoryAndReload() async {
    await context.push('/admin-mobile/marketplace/categories/new');
    if (!mounted) return;
    await _loadCategories(_api(context));
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final api = _api(context);
    final file = await picker.pickImage(source: source);
    if (file == null) return;
    setState(() => uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final result = await api.uploadMarketplaceImage(
        bytes,
        fileName: file.name,
      );
      if (!mounted) return;
      setState(() {
        imageUrl.text = _text(result, 'imageUrl');
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readApiError(error));
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Future<void> _save() async {
    if (categoryId.isEmpty) {
      _showMessage('Selecione uma categoria para o produto.');
      return;
    }

    setState(() => saving = true);

    final payload = {
      'productCategoryId': categoryId,
      'name': name.text.trim(),
      'shortDescription': shortDescription.text.trim(),
      'description': description.text.trim(),
      'price': _parseMoney(price.text) ?? 0,
      'promotionalPrice': _parseMoney(promotionalPrice.text),
      'mainImageUrl': imageUrl.text.trim().isEmpty
          ? null
          : imageUrl.text.trim(),
      'isActive': active,
      'isFeatured': featured,
      'displayOrder': 0,
      'stockQuantity': null,
      'images': imageUrl.text.trim().isEmpty
          ? []
          : [
              {
                'imageUrl': imageUrl.text.trim(),
                'displayOrder': 0,
                'isMain': true,
              },
            ],
    };

    debugPrint('Payload produto marketplace: $payload');

    try {
      await _api(context).saveMarketplaceProduct(widget.id, payload);
      if (!mounted) return;
      _showMessage('Produto salvo com sucesso.');
      context.pop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readSaveError(error));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  double? _parseMoney(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readSaveError(Object error) {
    final apiError = _apiException(error);
    final message = _readApiError(
      error,
      fallback: 'Nao foi possivel salvar o produto. Tente novamente.',
    );
    final normalized = message.toLowerCase();

    if (normalized.contains('categoria') ||
        normalized.contains('productcategoryid')) {
      return 'Selecione uma categoria para o produto.';
    }

    if (apiError?.statusCode == 400) {
      return message;
    }

    return message;
  }

  String _readApiError(
    Object error, {
    String fallback = 'Nao foi possivel concluir a operacao.',
  }) {
    final apiError = _apiException(error);
    if (apiError?.statusCode == 401) {
      return 'Sessao expirada. Faca login novamente.';
    }
    if (apiError != null) {
      if (apiError.errors.isNotEmpty) {
        return apiError.errors.join(' ');
      }
      if (apiError.message.isNotEmpty) {
        return apiError.message;
      }
    }
    return fallback;
  }

  ApiException? _apiException(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException && error.error is ApiException) {
      return error.error! as ApiException;
    }
    return null;
  }

  @override
  void dispose() {
    name.dispose();
    shortDescription.dispose();
    description.dispose();
    price.dispose();
    promotionalPrice.dispose();
    imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.id == null ? 'Novo produto' : 'Editar produto',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: categoryId.isEmpty ? null : categoryId,
            dropdownColor: AppColors.surfaceElevated,
            iconEnabledColor: AppColors.gold,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: _text(category, 'id'),
                    child: Text(_text(category, 'name')),
                  ),
                )
                .toList(),
            hint: const Text(
              'Selecione uma categoria',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            onChanged: loadingCategories || categories.isEmpty
                ? null
                : (value) => setState(() => categoryId = value ?? ''),
          ),
          if (loadingCategories) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(color: AppColors.gold),
          ],
          if (!loadingCategories && categories.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              categoriesError.isNotEmpty
                  ? categoriesError
                  : 'Nenhuma categoria da loja cadastrada. Cadastre uma categoria antes de criar produtos.',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _createCategoryAndReload,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar categoria da loja'),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: shortDescription,
            decoration: const InputDecoration(labelText: 'Descrição curta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Descrição completa'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Preço'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: promotionalPrice,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Preço promocional'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: imageUrl,
            decoration: const InputDecoration(labelText: 'Imagem principal'),
          ),
          const SizedBox(height: 8),
          if (uploading) const LinearProgressIndicator(color: AppColors.gold),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Câmera'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeria'),
              ),
            ],
          ),
          SwitchListTile(
            value: active,
            onChanged: (value) => setState(() => active = value),
            title: const Text('Ativo'),
          ),
          SwitchListTile(
            value: featured,
            onChanged: (value) => setState(() => featured = value),
            title: const Text('Destaque'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                saving || uploading || loadingCategories || categories.isEmpty
                ? null
                : _save,
            child: Text(saving ? 'Salvando...' : 'Salvar produto'),
          ),
        ],
      ),
    );
  }
}
