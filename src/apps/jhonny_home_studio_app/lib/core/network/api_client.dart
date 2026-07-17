import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({required TokenStorage tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (_requiresAuthorization(options.uri) &&
              (token == null || token.isEmpty)) {
            final apiException = ApiException(
              message: 'Sessão expirada. Faça login novamente.',
              statusCode: 401,
              errors: const ['Token ausente para rota administrativa.'],
            );
            handler.reject(
              DioException(
                requestOptions: options,
                error: apiException,
                type: DioExceptionType.unknown,
              ),
            );
            return;
          }

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            final authorization = options.headers['Authorization']?.toString();
            debugPrint(
              '[ApiClient] ${options.method} ${options.uri} tokenStored=${_maskToken(token)} authorization=${_maskAuthorization(authorization)}',
            );
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            final authorization = error.requestOptions.headers['Authorization']
                ?.toString();
            debugPrint(
              '[ApiClient] ERROR ${error.response?.statusCode} ${error.requestOptions.method} ${error.requestOptions.uri} authorization=${_maskAuthorization(authorization)}',
            );
          }
          if (error.response?.statusCode == 401) {
            await _tokenStorage.deleteToken();
          }
          handler.reject(_buildDioException(error));
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<String?> getToken() => _tokenStorage.getToken();

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _dio.get(path);
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? data}) async {
    final response = await _dio.post(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? data}) async {
    final response = await _dio.put(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? data}) async {
    final response = await _dio.patch(
      path,
      data: data,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path, {Object? data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return _normalizeResponse(response);
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    String? filePath,
    Uint8List? bytes,
    String fileName = 'upload.bin',
    Map<String, String>? fields,
  }) async {
    if (filePath == null && bytes == null) {
      throw ArgumentError('Informe filePath ou bytes para o upload.');
    }

    final uri = _resolveUri(path);
    final mimeType = _inferMimeType(fileName);
    final contentType = MediaType.parse(mimeType);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields ?? const <String, String>{});

    final token = await _tokenStorage.getToken();
    if (_requiresAuthorization(uri) && (token == null || token.isEmpty)) {
      throw ApiException(
        message: 'Sessão expirada. Faça login novamente.',
        statusCode: 401,
        errors: const ['Token ausente para rota administrativa.'],
      );
    }

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: contentType,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath!,
          filename: fileName,
          contentType: contentType,
        ),
      );
    }

    _logUploadRequest(uri, fields, fileName, mimeType, bytes?.length);

    try {
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(_uploadTimeout);

      _logUploadResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _apiExceptionFromHttpResponse(response);
      }

      return _normalizeHttpResponse(response);
    } on TimeoutException {
      throw ApiException(message: 'Tempo esgotado ao enviar a mídia.');
    } on http.ClientException catch (error) {
      throw ApiException(message: _uploadClientMessage(error.message));
    } on FormatException {
      throw ApiException(message: 'Falha ao interpretar a resposta do upload.');
    }
  }

  static const Duration _uploadTimeout = Duration(seconds: 60);

  Map<String, dynamic> _normalizeResponse(Response<dynamic> response) {
    final payload = _decodeResponse(response.data);
    return _normalizePayload(payload, response.statusCode);
  }

  Map<String, dynamic> _normalizeHttpResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw ApiException(
        message: 'Resposta vazia da API após o upload.',
        statusCode: response.statusCode,
      );
    }

    final payload = _decodeResponse(response.body);
    return _normalizePayload(payload, response.statusCode);
  }

  Map<String, dynamic> _normalizePayload(dynamic payload, int? statusCode) {
    if (payload is! Map<String, dynamic>) {
      throw ApiException(
        message: 'Resposta inválida da API.',
        statusCode: statusCode,
      );
    }

    final success = payload['success'];
    final message = payload['message']?.toString() ?? 'Erro inesperado.';
    final errors = _extractErrors(payload['errors']);

    if (success == false) {
      throw ApiException(
        message: message,
        statusCode: statusCode,
        errors: errors,
      );
    }

    return payload;
  }

  ApiException _apiExceptionFromHttpResponse(http.Response response) {
    final payload = _tryDecodeResponse(response.body);
    if (payload is Map<String, dynamic>) {
      final message =
          payload['message']?.toString() ?? _statusMessage(response.statusCode);
      final errors = _extractErrors(payload['errors']);
      return ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return ApiException(
      message: _statusMessage(response.statusCode),
      statusCode: response.statusCode,
    );
  }

  dynamic _decodeResponse(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return jsonDecode(data);
    }
    return data;
  }

  dynamic _tryDecodeResponse(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  List<String> _extractErrors(dynamic errors) {
    if (errors is List) {
      return errors.map((item) => item.toString()).toList();
    }
    if (errors is Map) {
      return errors.values.map((item) => item.toString()).toList();
    }
    return const [];
  }

  DioException _buildDioException(DioException error) {
    final response = error.response;
    if (response?.data is Map<String, dynamic>) {
      final payload = response!.data as Map<String, dynamic>;
      final message = payload['message']?.toString() ?? _defaultMessage(error);
      final errors = _extractErrors(payload['errors']);
      return DioException(
        requestOptions: error.requestOptions,
        response: response,
        error: ApiException(
          message: message,
          statusCode: response.statusCode,
          errors: errors,
        ),
        type: error.type,
      );
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: response,
      error: ApiException(message: _defaultMessage(error)),
      type: error.type,
    );
  }

  String _defaultMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tempo esgotado ao conectar com a API.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar com a API.';
      case DioExceptionType.badResponse:
        return 'A API retornou uma resposta inválida.';
      case DioExceptionType.cancel:
        return 'Requisição cancelada.';
      case DioExceptionType.badCertificate:
        return 'Certificado inválido.';
      case DioExceptionType.unknown:
        return 'Erro inesperado de rede.';
    }
  }

  Uri _resolveUri(String path) {
    if (Uri.tryParse(path)?.hasScheme == true) {
      return Uri.parse(path);
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalizedPath');
  }

  String _inferMimeType(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    if (normalized.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (normalized.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (normalized.endsWith('.webm')) {
      return 'video/webm';
    }

    return 'application/octet-stream';
  }

  void _logUploadRequest(
    Uri uri,
    Map<String, String>? fields,
    String fileName,
    String mimeType,
    int? sizeBytes,
  ) {
    debugPrint('UPLOAD URL: $uri');
    debugPrint('UPLOAD FOLDER: ${fields?['folder'] ?? ''}');
    debugPrint('UPLOAD FILE: $fileName');
    debugPrint('UPLOAD MIME: $mimeType');
    debugPrint('UPLOAD SIZE: ${sizeBytes ?? -1}');
  }

  void _logUploadResponse(http.Response response) {
    debugPrint('UPLOAD STATUS: ${response.statusCode}');
    debugPrint('UPLOAD BODY: ${_trimForLog(response.body)}');
  }

  String _trimForLog(String value) {
    const maxLength = 2000;
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
  }

  String _uploadClientMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('xmlhttprequest') || normalized.contains('cors')) {
      return 'Falha de rede ou CORS no upload. Verifique se a API respondeu com Access-Control-Allow-Origin.';
    }

    return 'Não foi possível conectar com a API durante o upload.';
  }

  String _statusMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'Falha no upload: requisição inválida.',
      401 => 'Sessão expirada.',
      403 => 'Você não tem permissão para enviar mídia.',
      413 => 'Falha no upload: arquivo muito grande.',
      415 => 'Falha no upload: formato não permitido.',
      >= 500 => 'Erro interno no upload.',
      _ => 'Falha no upload. Status HTTP $statusCode.',
    };
  }

  bool _requiresAuthorization(Uri uri) {
    return uri.path.contains('/admin/');
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
}
