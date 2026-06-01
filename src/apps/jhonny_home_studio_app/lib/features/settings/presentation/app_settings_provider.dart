import 'package:flutter/foundation.dart';

import '../data/app_settings_api.dart';
import '../data/app_settings_model.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettingsProvider({required AppSettingsApi api})
    : _loadPublicSettings = api.getPublicSettings;

  @visibleForTesting
  AppSettingsProvider.withLoader({
    required Future<AppSettingsModel> Function() loadPublicSettings,
  }) : _loadPublicSettings = loadPublicSettings;

  final Future<AppSettingsModel> Function() _loadPublicSettings;
  AppSettingsModel _settings = AppSettingsModel.fallback;

  AppSettingsModel get settings => _settings;

  Future<void> loadSettings() async {
    try {
      _settings = await _loadPublicSettings();
      notifyListeners();
    } catch (_) {
      _settings = AppSettingsModel.fallback;
      notifyListeners();
    }
  }
}
