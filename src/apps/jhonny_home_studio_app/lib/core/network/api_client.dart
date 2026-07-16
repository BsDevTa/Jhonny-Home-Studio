import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
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
    final response = await _dio.post(path, data: data);
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? data}) async {
    final response = await _dio.put(path, data: data);
    return _normalizeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? data}) async {
    final response = await _dio.patch(path, data: data);
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

    final formData = FormData.fromMap({
      'file': bytes != null
          ? MultipartFile.fromBytes(bytes, filename: fileName)
          : await MultipartFile.fromFile(filePath!),
      if (fields != null) ...fields,
    });
    final response = await _dio.post(path, data: formData);
    return _normalizeResponse(response);
  }

  Map<String, dynamic> _normalizeResponse(Response<dynamic> response) {
    final payload = _decodeResponse(response.data);
    if (payload is! Map<String, dynamic>) {
      throw ApiException(message: 'Resposta inválida da API.');
    }

    final success = payload['success'];
    final message = payload['message']?.toString() ?? 'Erro inesperado.';
    final errors = _extractErrors(payload['errors']);

    if (success == false) {
      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return payload;
  }

  dynamic _decodeResponse(dynamic data) {
    if (data is String && data.isNotEmpty) {
      return jsonDecode(data);
    }
    return data;
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
