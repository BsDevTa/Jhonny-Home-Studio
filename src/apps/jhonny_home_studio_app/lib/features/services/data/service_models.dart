class ServiceCategoryModel {
  ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final bool isActive;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      description: _readString(json, 'description'),
      isActive: _readBool(json, 'isActive', defaultValue: true),
    );
  }
}

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.estimatedDurationMinutes,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String serviceCategoryId;
  final String serviceCategoryName;
  final String name;
  final String description;
  final double price;
  final int estimatedDurationMinutes;
  final String imageUrl;
  final bool isActive;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final category = json['serviceCategory'];
    final categoryMap = category is Map<String, dynamic> ? category : null;

    return ServiceModel(
      id: _readString(json, 'id'),
      serviceCategoryId: _readString(
        json,
        'serviceCategoryId',
        fallback: categoryMap,
      ),
      serviceCategoryName: _readString(
        json,
        'serviceCategoryName',
        fallback: categoryMap,
        fallbackKey: 'name',
      ),
      name: _readString(json, 'name'),
      description: _readString(json, 'description'),
      price: _readDouble(json, 'price'),
      estimatedDurationMinutes: _readInt(json, 'estimatedDurationMinutes'),
      imageUrl: _readString(json, 'imageUrl'),
      isActive: _readBool(json, 'isActive', defaultValue: true),
    );
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  Map<String, dynamic>? fallback,
  String? fallbackKey,
}) {
  final directValue = json[key];
  if (directValue != null && directValue.toString().isNotEmpty) {
    return directValue.toString();
  }

  if (fallback != null) {
    final candidate = fallback[fallbackKey ?? key];
    if (candidate != null && candidate.toString().isNotEmpty) {
      return candidate.toString();
    }
  }

  return '';
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
