import '../../../core/utils/media_url_resolver.dart';
import '../../../core/utils/service_presentation_formatter.dart';

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isActive;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      description: _readString(json, 'description'),
      price: _readDouble(json, 'price'),
      imageUrl: resolveMediaUrl(_readString(json, 'imageUrl')),
      isActive: _readBool(json, 'isActive', defaultValue: true),
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value != null && value.toString().isNotEmpty) {
    return ServicePresentationFormatter.sanitizeNullableText(value.toString());
  }

  return '';
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  bool defaultValue = false,
}) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return defaultValue;
}
