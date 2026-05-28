import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'address_models.dart';

class AddressesApi {
  AddressesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AddressModel>> getMyAddresses() async {
    final response = await _apiClient.getJson('/customers/me/addresses');
    final data = response['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AddressModel.fromJson)
        .toList(growable: false);
  }

  Future<AddressModel> getMyAddressById(String id) async {
    final response = await _apiClient.getJson('/customers/me/addresses/$id');
    return _readAddress(response['data']);
  }

  Future<AddressModel> createAddress(CreateAddressRequest request) async {
    final response = await _apiClient.postJson(
      '/customers/me/addresses',
      data: request.toJson(),
    );
    return _readAddress(response['data']);
  }

  Future<AddressModel> updateAddress(
    String id,
    UpdateAddressRequest request,
  ) async {
    final response = await _apiClient.putJson(
      '/customers/me/addresses/$id',
      data: request.toJson(),
    );
    return _readAddress(response['data']);
  }

  Future<void> deleteAddress(String id) async {
    await _apiClient.deleteJson('/customers/me/addresses/$id');
  }

  Future<void> setDefaultAddress(String id) async {
    await _apiClient.patchJson('/customers/me/addresses/$id/set-default');
  }

  AddressModel _readAddress(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Endereço inválido retornado pela API.');
    }
    return AddressModel.fromJson(data);
  }
}
