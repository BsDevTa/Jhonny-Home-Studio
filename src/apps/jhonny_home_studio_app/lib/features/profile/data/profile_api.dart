import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'profile_models.dart';

class ProfileApi {
  ProfileApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<CustomerProfileModel> getMyProfile() async {
    final response = await _apiClient.getJson('/customers/me');
    return _readProfile(response['data']);
  }

  Future<CustomerProfileModel> updateMyProfile(
    UpdateCustomerProfileRequest request,
  ) async {
    final response = await _apiClient.putJson(
      '/customers/me',
      data: request.toJson(),
    );
    return _readProfile(response['data']);
  }

  CustomerProfileModel _readProfile(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        message: 'Dados de perfil inválidos retornados pela API.',
      );
    }
    return CustomerProfileModel.fromJson(data);
  }
}
