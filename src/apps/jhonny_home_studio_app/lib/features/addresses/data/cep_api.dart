import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import 'cep_model.dart';

class CepApi {
  CepApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://viacep.com.br/ws',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<CepModel> getAddressByCep(String cep) async {
    final normalizedCep = cep.replaceAll(RegExp(r'\D'), '');
    if (normalizedCep.length != 8) {
      throw ApiException(message: 'Informe um CEP válido com 8 números.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/$normalizedCep/json/',
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(message: 'Não foi possível consultar o CEP agora.');
      }

      final address = CepModel.fromJson(data);
      if (address.erro) {
        throw ApiException(message: 'CEP não encontrado.');
      }

      return address;
    } on ApiException {
      rethrow;
    } on DioException catch (_) {
      throw ApiException(message: 'Não foi possível consultar o CEP agora.');
    } catch (_) {
      throw ApiException(message: 'Não foi possível consultar o CEP agora.');
    }
  }
}
