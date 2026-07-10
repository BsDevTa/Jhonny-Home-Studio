import '../../../core/utils/media_url_resolver.dart';

class StoryModel {
  StoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.serviceId,
    required this.serviceName,
    required this.displayOrder,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String mediaUrl;
  final String mediaType;
  final String serviceId;
  final String serviceName;
  final int displayOrder;

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasMedia => mediaUrl.trim().isNotEmpty;
  bool get isVideo => mediaType.toLowerCase() == 'video';
  bool get hasLinkedService => serviceId.trim().isNotEmpty;
  String get visualUrl => hasImage ? imageUrl : mediaUrl;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final imageUrl = readMediaUrl(json, const [
      'imageUrl',
      'ImageUrl',
      'mediaUrl',
      'MediaUrl',
      'url',
      'fileUrl',
    ]);
    final mediaUrl = readMediaUrl(json, const [
      'mediaUrl',
      'MediaUrl',
      'imageUrl',
      'ImageUrl',
      'url',
      'fileUrl',
    ]);

    return StoryModel(
      id: _readString(json, 'id'),
      title: _readString(json, 'title'),
      subtitle: _readString(json, 'subtitle'),
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      mediaType: _readMediaType(json),
      serviceId: _readString(json, 'serviceId'),
      serviceName: _readString(json, 'serviceName'),
      displayOrder: _readInt(json, 'displayOrder'),
    );
  }
}

String _readMediaType(Map<String, dynamic> json) {
  final explicit = _readString(json, 'mediaType');
  if (explicit.isNotEmpty) {
    return explicit;
  }
  final url = _readString(json, 'mediaUrl').isEmpty
      ? _readString(json, 'imageUrl')
      : _readString(json, 'mediaUrl');
  return RegExp(r'\.(mp4|mov|webm)(\?|$)', caseSensitive: false).hasMatch(url)
      ? 'Video'
      : 'Image';
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? '' : value.toString();
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
