import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login(String email, String password) async {
    final response = await _apiClient.postJson(
      '/auth/login',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    return _saveAndBuildUser(response);
  }

  Future<AuthUser> register(RegisterCustomerRequest request) async {
    final response = await _apiClient.postJson(
      '/auth/register-customer',
      data: request.toJson(),
    );
    return _saveAndBuildUser(response);
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  Future<String?> getToken() async {
    return _tokenStorage.getToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthUser> _saveAndBuildUser(Map<String, dynamic> response) async {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Dados de autenticação inválidos.');
    }

    final user = AuthUser.fromJson(data);
    if (user.token.isEmpty) {
      throw ApiException(message: 'Token de autenticação não encontrado.');
    }

    await _tokenStorage.saveToken(user.token);
    return user;
  }
}
