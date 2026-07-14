import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'service_models.dart';

class ServicesApi {
  ServicesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ServiceModel>> getActiveServices() async {
    final response = await _apiClient.getJson('/services/active');
    return _readServiceList(response['data']);
  }

  Future<ServiceModel> getServiceById(String id) async {
    final response = await _apiClient.getJson('/services/$id');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Servico invalido retornado pela API.');
    }
    return ServiceModel.fromJson(data);
  }

  List<ServiceModel> _readServiceList(dynamic data) {
    final items = _extractList(data);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList(growable: false);
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      for (final key in const ['items', 'results', 'data']) {
        final value = data[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const [];
  }
}
