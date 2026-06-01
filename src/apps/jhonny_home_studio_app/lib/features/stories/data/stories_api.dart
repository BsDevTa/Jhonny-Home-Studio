import '../../../core/network/api_client.dart';
import 'story_model.dart';

class StoriesApi {
  StoriesApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<StoryModel>> getActiveStories() async {
    final response = await _apiClient.getJson('/stories/active');
    final data = response['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(StoryModel.fromJson)
        .toList(growable: false);
  }
}
