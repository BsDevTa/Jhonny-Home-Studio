import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';

class AdminMobileApi {
  AdminMobileApi({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getServices() =>
      _getList('/admin/services');
  Future<Map<String, dynamic>> getService(String id) =>
      _getObject('/services/$id');
  Future<void> saveService(String? id, Map<String, dynamic> data) => id == null
      ? _post('/admin/services', data)
      : _put('/admin/services/$id', data);
  Future<void> toggleService(String id, bool active) =>
      _patch('/admin/services/$id/${active ? 'activate' : 'deactivate'}');
  Future<void> deleteService(String id) => _delete('/admin/services/$id');
  Future<Map<String, dynamic>> uploadServiceImage(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final response = await _api.postMultipart(
      '/admin/stories/upload-media',
      bytes: bytes,
      fileName: fileName,
      fields: const {'folder': 'services'},
    );
    debugPrint('Resposta completa upload-media: $response');
    final normalized = _normalizeUploadResponse(_asMap(response['data']));
    debugPrint('URL definitiva recebida: ${readUploadUrl(normalized)}');
    return normalized;
  }

  Future<List<Map<String, dynamic>>> getAppointments({
    String? date,
    String? customerId,
  }) {
    final query = <String, String>{};
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (customerId != null && customerId.isNotEmpty) {
      query['customerId'] = customerId;
    }
    return _getList(
      Uri(path: '/admin/appointments', queryParameters: query).toString(),
    );
  }

  Future<Map<String, dynamic>> getAppointment(String id) =>
      _getObject('/admin/appointments/$id');
  Future<void> updateAppointmentStatus(String id, String status, String note) =>
      _patch('/admin/appointments/$id/status', {
        'status': status,
        'note': note,
      });

  Future<List<Map<String, dynamic>>> getCustomers() =>
      _getList('/admin/customers');
  Future<Map<String, dynamic>> getCustomer(String id) =>
      _getObject('/admin/customers/$id');
  Future<List<Map<String, dynamic>>> getCustomerAddresses(String id) =>
      _getList('/admin/customers/$id/addresses');
  Future<Map<String, dynamic>> getCustomerLoyalty(String id) =>
      _getObject('/admin/customers/$id/loyalty');
  Future<void> toggleCustomer(String id, bool active) =>
      _patch('/admin/customers/$id/${active ? 'activate' : 'deactivate'}');

  Future<List<Map<String, dynamic>>> getStories() => _getList('/admin/stories');
  Future<Map<String, dynamic>> getStory(String id) =>
      _getObject('/admin/stories/$id');
  Future<void> saveStory(String? id, Map<String, dynamic> data) => id == null
      ? _post('/admin/stories', data)
      : _put('/admin/stories/$id', data);
  Future<void> toggleStory(String id) =>
      _patch('/admin/stories/$id/toggle-active');
  Future<void> deleteStory(String id) => _delete('/admin/stories/$id');
  Future<Map<String, dynamic>> uploadStoryMedia(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final response = await _api.postMultipart(
      '/admin/stories/upload-media',
      bytes: bytes,
      fileName: fileName,
    );
    debugPrint('Resposta completa upload-media: $response');
    final normalized = _normalizeUploadResponse(_asMap(response['data']));
    debugPrint('URL definitiva recebida: ${readUploadUrl(normalized)}');
    return normalized;
  }

  Future<Map<String, dynamic>> getSettings() => _getObject('/admin/settings');
  Future<void> saveSettings(Map<String, dynamic> data) =>
      _put('/admin/settings', data);

  Future<List<Map<String, dynamic>>> getBusinessHours() =>
      _getList('/admin/availability/business-hours');
  Future<void> saveBusinessHours(List<Map<String, dynamic>> data) =>
      _put('/admin/availability/business-hours', data);
  Future<List<Map<String, dynamic>>> getBlockedDates() =>
      _getList('/admin/availability/blocked-dates');
  Future<Map<String, dynamic>> getBlockedDate(String id) =>
      _getObject('/admin/availability/blocked-dates/$id');
  Future<void> saveBlockedDate(String? id, Map<String, dynamic> data) =>
      id == null
      ? _post('/admin/availability/blocked-dates', data)
      : _put('/admin/availability/blocked-dates/$id', data);
  Future<void> deleteBlockedDate(String id) =>
      _delete('/admin/availability/blocked-dates/$id');

  Future<List<Map<String, dynamic>>> getMarketplaceProducts() =>
      _getList('/admin/marketplace/products');
  Future<Map<String, dynamic>> getMarketplaceProduct(String id) =>
      _getObject('/admin/marketplace/products/$id');
  Future<void> saveMarketplaceProduct(String? id, Map<String, dynamic> data) =>
      id == null
      ? _post('/admin/marketplace/products', data)
      : _put('/admin/marketplace/products/$id', data);
  Future<void> toggleMarketplaceProduct(String id) =>
      _patch('/admin/marketplace/products/$id/toggle-active');
  Future<void> deleteMarketplaceProduct(String id) =>
      _delete('/admin/marketplace/products/$id');
  Future<Map<String, dynamic>> uploadMarketplaceImage(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/admin/marketplace/products/upload-image',
    );
    final request = http.MultipartRequest('POST', uri);

    final token = await _api.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (kDebugMode) {
      debugPrint(
        '[AdminMobileApi] POST $uri tokenStored=${_maskToken(token)} authorization=${_maskAuthorization(request.headers['Authorization'])}',
      );
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        message: response.body,
        statusCode: response.statusCode,
      );
    }

    final decoded = _decodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return _normalizeUploadResponse(data);
      }
      return _normalizeUploadResponse(decoded);
    }

    return const <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await _api.getJson(path);
    return _asList(response['data']);
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    final response = await _api.getJson(path);
    return _asMap(response['data']);
  }

  Future<void> _post(String path, Object? data) async {
    await _api.postJson(path, data: data);
  }

  Future<void> _put(String path, Object? data) async {
    await _api.putJson(path, data: data);
  }

  Future<void> _patch(String path, [Object? data]) async {
    await _api.patchJson(path, data: data);
  }

  Future<void> _delete(String path) async {
    await _api.deleteJson(path);
  }
}

List<Map<String, dynamic>> _asList(dynamic value) {
  return value is List
      ? value.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

dynamic _decodeBody(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return const <String, dynamic>{};
  }

  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return trimmed;
  }
}

Map<String, dynamic> _normalizeUploadResponse(Map<String, dynamic> value) {
  final normalized = Map<String, dynamic>.from(value);
  final uploadedUrl = readUploadUrl(normalized);
  if (uploadedUrl.isNotEmpty) {
    normalized['imageUrl'] = uploadedUrl;
    normalized['mediaUrl'] = uploadedUrl;
  }

  for (final key in ['imageUrl', 'mediaUrl', 'url', 'fileUrl']) {
    final raw = normalized[key];
    if (raw is String && raw.isNotEmpty) {
      normalized[key] = _ensureHttps(raw);
    }
  }
  return normalized;
}

String readUploadUrl(Map<String, dynamic> value) {
  for (final key in const ['imageUrl', 'mediaUrl', 'url', 'fileUrl']) {
    final raw = value[key]?.toString().trim() ?? '';
    if (raw.isNotEmpty) {
      return _ensureHttps(raw);
    }
  }

  return '';
}

String _ensureHttps(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return text;
  }

  final parsed = Uri.tryParse(text);
  if (parsed?.scheme == 'http') {
    return parsed!.replace(scheme: 'https').toString();
  }

  return text;
}

String _maskAuthorization(String? authorization) {
  if (authorization == null || authorization.isEmpty) {
    return '<missing>';
  }

  const prefix = 'Bearer ';
  if (!authorization.startsWith(prefix)) {
    return '<present non-bearer>';
  }

  return 'Bearer ${_maskToken(authorization.substring(prefix.length))}';
}

String _maskToken(String? token) {
  if (token == null || token.isEmpty) {
    return '<empty>';
  }

  if (token.length <= 16) {
    return '$token(len=${token.length})';
  }

  return '${token.substring(0, 12)}...${token.substring(token.length - 8)}(len=${token.length})';
}
