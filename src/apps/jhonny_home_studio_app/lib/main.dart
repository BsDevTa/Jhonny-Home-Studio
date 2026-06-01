import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/settings/data/app_settings_api.dart';
import 'features/settings/presentation/app_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authService = AuthService(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final authProvider = AuthProvider(authService: authService);
  final appSettingsProvider = AppSettingsProvider(
    api: AppSettingsApi(apiClient: apiClient),
  );
  appSettingsProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AppSettingsProvider>.value(
          value: appSettingsProvider,
        ),
      ],
      child: const JhonnyHomeStudioApp(),
    ),
  );
}
