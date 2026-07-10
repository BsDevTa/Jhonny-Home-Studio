import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/config/api_config.dart';
import 'package:jhonny_home_studio_app/core/utils/media_url_resolver.dart';

void main() {
  test('rejeita URL temporaria blob do navegador', () {
    expect(resolveMediaUrl('blob:https://johnny-home-studio.web.app/abc'), '');
  });

  test('mantem URL absoluta', () {
    expect(
      resolveMediaUrl('https://cdn.example.com/story.jpeg'),
      'https://cdn.example.com/story.jpeg',
    );
  });

  test('converte URL relativa para origem da API', () {
    expect(
      resolveMediaUrl('/uploads/stories/story.jpeg'),
      '${ApiConfig.apiOrigin}/uploads/stories/story.jpeg',
    );
  });
}
