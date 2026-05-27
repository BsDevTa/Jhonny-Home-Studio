import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/auth_models.dart';
import '../data/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  bool _isLoading = false;
  AuthUser? _user;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.login(email, password);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _setError(error.message);
      return false;
    } catch (_) {
      _setError('Não foi possível entrar. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(RegisterCustomerRequest request) async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authService.register(request);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _setError(error.message);
      return false;
    } catch (_) {
      _setError('Não foi possível criar a conta. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _clearError();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    _clearError();
    try {
      final loggedIn = await _authService.isLoggedIn();
      _isAuthenticated = loggedIn;
      if (!loggedIn) {
        _user = null;
      }
      notifyListeners();
      return loggedIn;
    } catch (_) {
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
