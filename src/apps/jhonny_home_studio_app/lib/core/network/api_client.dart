import 'dart:convert';

import 'package:dio/dio.dart';

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
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(_buildDioException(error));
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

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

  Future<Map<String, dynamic>> deleteJson(String path, {Object? data}) async {
    final response = await _dio.delete(path, data: data);
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
}
