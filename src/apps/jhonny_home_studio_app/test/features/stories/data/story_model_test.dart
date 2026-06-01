import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/features/stories/data/story_model.dart';

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

    expect(story.imageUrl, 'http://localhost:5299/uploads/stories/story.webp');
  });

  test('mantém placeholder disponível quando story não possui imagem', () {
    final story = StoryModel.fromJson({'id': 'story-3', 'title': 'Destaque'});

    expect(story.imageUrl, isEmpty);
    expect(story.hasImage, isFalse);
  });
}
