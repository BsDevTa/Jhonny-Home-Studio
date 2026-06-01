import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'app_settings_model.dart';

class AppSettingsApi {
  AppSettingsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AppSettingsModel> getPublicSettings() async {
    final response = await _apiClient.getJson('/settings/public');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        message: 'Configurações inválidas retornadas pela API.',
      );
    }

    return AppSettingsModel.fromJson(data);
  }
}
