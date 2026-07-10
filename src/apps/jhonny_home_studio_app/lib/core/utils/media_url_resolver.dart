import '../config/api_config.dart';

String resolveMediaUrl(String? value) {
  final url = value?.trim() ?? '';
  if (url.isEmpty) {
    return '';
  }

  if (url.startsWith('blob:')) {
    return '';
  }

  final parsed = Uri.tryParse(url);
  if (parsed?.scheme == 'http') {
    return parsed!.replace(scheme: 'https').toString();
  }

  if (parsed?.hasScheme == true) {
    return url;
  }

  final path = url.startsWith('/') ? url : '/$url';
  return '${ApiConfig.apiOrigin}$path';
}

String readMediaUrl(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return resolveMediaUrl(value);
    }
  }

  return '';
}
