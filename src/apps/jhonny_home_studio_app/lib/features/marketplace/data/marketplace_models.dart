import '../../../core/utils/media_url_resolver.dart';

class ProductImageModel {
  const ProductImageModel({required this.imageUrl, required this.isMain});

  final String imageUrl;
  final bool isMain;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      imageUrl: resolveMediaUrl(_readString(json, 'imageUrl')),
      isMain: _readBool(json, 'isMain'),
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.price,
    required this.promotionalPrice,
    required this.mainImageUrl,
    required this.isFeatured,
    required this.stockQuantity,
    required this.images,
  });

  final String id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final double? promotionalPrice;
  final String mainImageUrl;
  final bool isFeatured;
  final int? stockQuantity;
  final List<ProductImageModel> images;

  double get currentPrice => promotionalPrice ?? price;
  bool get hasPromotionalPrice =>
      promotionalPrice != null && promotionalPrice! > 0;
  String get displayImageUrl {
    if (mainImageUrl.trim().isNotEmpty) {
      return mainImageUrl.trim();
    }

    final mainImage = images
        .where((image) => image.isMain)
        .map((image) => image.imageUrl.trim())
        .where((imageUrl) => imageUrl.isNotEmpty);

    if (mainImage.isNotEmpty) {
      return mainImage.first;
    }

    return images
        .map((image) => image.imageUrl.trim())
        .firstWhere((imageUrl) => imageUrl.isNotEmpty, orElse: () => '');
  }

  bool get hasImage => displayImageUrl.trim().isNotEmpty;
  bool get isAvailable => stockQuantity == null || stockQuantity! > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    return ProductModel(
      id: _readString(json, 'id'),
      name: _readString(json, 'name'),
      description: _readString(json, 'description'),
      shortDescription: _readString(json, 'shortDescription'),
      price: _readDouble(json, 'price'),
      promotionalPrice: _readNullableDouble(json, 'promotionalPrice'),
      mainImageUrl: resolveMediaUrl(_readString(json, 'mainImageUrl')),
      isFeatured: _readBool(json, 'isFeatured'),
      stockQuantity: _readNullableInt(json, 'stockQuantity'),
      images: images is List
          ? images
                .whereType<Map<String, dynamic>>()
                .map(ProductImageModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

String _readString(Map<String, dynamic> json, String key) =>
    json[key]?.toString().trim() ?? '';

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  return value?.toString().toLowerCase() == 'true';
}

double _readDouble(Map<String, dynamic> json, String key) =>
    _readNullableDouble(json, key) ?? 0;

double? _readNullableDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

int? _readNullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}
