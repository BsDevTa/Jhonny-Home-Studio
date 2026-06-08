import '../../../core/network/api_client.dart';
import 'marketplace_models.dart';

class MarketplaceApi {
  MarketplaceApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ProductCategoryModel>> getCategories() async {
    final response = await _apiClient.getJson('/marketplace/categories');
    final data = response['data'];
    return data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(ProductCategoryModel.fromJson)
              .toList(growable: false)
        : const [];
  }

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    bool? featured,
    String? search,
  }) async {
    final query = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (featured != null) {
      query['featured'] = featured.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final path = Uri(
      path: '/marketplace/products',
      queryParameters: query,
    ).toString();
    final response = await _apiClient.getJson(path);
    final data = response['data'];
    return data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList(growable: false)
        : const [];
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await _apiClient.getJson('/marketplace/products/featured');
    final data = response['data'];
    return data is List
        ? data
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList(growable: false)
        : const [];
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _apiClient.getJson('/marketplace/products/$id');
    final data = response['data'];
    return ProductModel.fromJson(data is Map<String, dynamic> ? data : {});
  }
}
