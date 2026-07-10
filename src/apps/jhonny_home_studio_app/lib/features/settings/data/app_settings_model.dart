import '../../../core/constants/app_texts.dart';
import '../../../core/utils/media_url_resolver.dart';

class AppSettingsModel {
  const AppSettingsModel({
    required this.studioName,
    required this.subtitle,
    required this.slogan,
    required this.logoUrl,
    required this.whatsAppNumber,
    required this.instagramUrl,
    required this.welcomeTitle,
    required this.welcomeMessage,
    required this.supportMessage,
  });

  final String studioName;
  final String subtitle;
  final String slogan;
  final String logoUrl;
  final String whatsAppNumber;
  final String instagramUrl;
  final String welcomeTitle;
  final String welcomeMessage;
  final String supportMessage;

  static const fallback = AppSettingsModel(
    studioName: AppTexts.appName,
    subtitle: AppTexts.appSubtitle,
    slogan: AppTexts.slogan,
    logoUrl: '',
    whatsAppNumber: '',
    instagramUrl: '',
    welcomeTitle: AppTexts.beautyBegins,
    welcomeMessage: AppTexts.slogan,
    supportMessage: 'Como podemos ajudar?',
  );

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      studioName: _readString(json, 'studioName', fallback: AppTexts.appName),
      subtitle: _readString(json, 'subtitle', fallback: AppTexts.appSubtitle),
      slogan: _readString(json, 'slogan', fallback: AppTexts.slogan),
      logoUrl: resolveMediaUrl(_readString(json, 'logoUrl')),
      whatsAppNumber: _readString(json, 'whatsAppNumber'),
      instagramUrl: _readString(json, 'instagramUrl'),
      welcomeTitle: _readString(
        json,
        'welcomeTitle',
        fallback: AppTexts.beautyBegins,
      ),
      welcomeMessage: _readString(
        json,
        'welcomeMessage',
        fallback: AppTexts.slogan,
      ),
      supportMessage: _readString(
        json,
        'supportMessage',
        fallback: 'Como podemos ajudar?',
      ),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key]?.toString().trim() ?? '';
  return value.isEmpty ? fallback : value;
}
