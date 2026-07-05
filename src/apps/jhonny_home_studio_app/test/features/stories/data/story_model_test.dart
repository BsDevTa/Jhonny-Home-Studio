import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/features/stories/data/story_model.dart';
import 'package:jhonny_home_studio_app/core/config/api_config.dart';

void main() {
  test('mantém URL absoluta da imagem do story', () {
    final story = StoryModel.fromJson({
      'id': 'story-1',
      'title': 'Destaque',
      'imageUrl': 'https://cdn.example.com/story.webp',
    });

    expect(story.imageUrl, 'https://cdn.example.com/story.webp');
  });

  test('completa URL relativa da imagem do story com a origem da API', () {
    final story = StoryModel.fromJson({
      'id': 'story-2',
      'title': 'Destaque',
      'imageUrl': '/uploads/stories/story.webp',
    });

    expect(story.imageUrl, '${ApiConfig.apiOrigin}/uploads/stories/story.webp');
    expect(
      story.visualUrl,
      '${ApiConfig.apiOrigin}/uploads/stories/story.webp',
    );
  });

  test('usa mediaUrl quando imageUrl não vem no payload', () {
    final story = StoryModel.fromJson({
      'id': 'story-2b',
      'title': 'Destaque',
      'mediaUrl': '/uploads/stories/story.webp',
    });

    expect(story.imageUrl, isEmpty);
    expect(story.mediaUrl, '${ApiConfig.apiOrigin}/uploads/stories/story.webp');
    expect(
      story.visualUrl,
      '${ApiConfig.apiOrigin}/uploads/stories/story.webp',
    );
  });

  test('mantém placeholder disponível quando story não possui imagem', () {
    final story = StoryModel.fromJson({'id': 'story-3', 'title': 'Destaque'});

    expect(story.imageUrl, isEmpty);
    expect(story.hasImage, isFalse);
  });

  test('identifica video preservando fallback pelo imageUrl', () {
    final story = StoryModel.fromJson({
      'id': 'story-4',
      'title': 'Video',
      'imageUrl': '/uploads/stories/story.mp4',
    });

    expect(story.isVideo, isTrue);
    expect(story.mediaUrl, '${ApiConfig.apiOrigin}/uploads/stories/story.mp4');
  });
}
