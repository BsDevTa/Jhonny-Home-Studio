import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/constants/app_texts.dart';
import 'package:jhonny_home_studio_app/features/settings/data/app_settings_model.dart';
import 'package:jhonny_home_studio_app/features/settings/presentation/app_settings_provider.dart';

void main() {
  test('usa fallbacks locais para campos públicos vazios', () {
    final settings = AppSettingsModel.fromJson({});

    expect(settings.studioName, AppTexts.appName);
    expect(settings.subtitle, AppTexts.appSubtitle);
    expect(settings.slogan, AppTexts.slogan);
    expect(settings.logoUrl, isEmpty);
  });

  test('completa URL relativa da logo com a origem da API', () {
    final settings = AppSettingsModel.fromJson({
      'logoUrl': '/uploads/logo.png',
    });

    expect(settings.logoUrl, 'http://localhost:5299/uploads/logo.png');
  });

  test('mantém fallback local quando carregamento remoto falha', () async {
    final provider = AppSettingsProvider.withLoader(
      loadPublicSettings: () => Future.error(Exception('API indisponível')),
    );

    await provider.loadSettings();

    expect(provider.settings.studioName, AppTexts.appName);
    expect(provider.settings.slogan, AppTexts.slogan);
  });
}
