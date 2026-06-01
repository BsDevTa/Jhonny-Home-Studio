import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'loyalty_model.dart';

class LoyaltyApi {
  LoyaltyApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LoyaltyModel> getMyLoyalty() async {
    final response = await _apiClient.getJson('/loyalty/my');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Fidelidade inválida retornada pela API.');
    }

    return LoyaltyModel.fromJson(data);
  }
}
