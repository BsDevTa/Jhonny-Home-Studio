import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/errors/api_exception.dart';
import 'package:jhonny_home_studio_app/features/addresses/data/cep_api.dart';

void main() {
  test('normaliza o CEP e converte o endereço retornado pelo ViaCEP', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/01001000/json/');
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'cep': '01001-000',
                'logradouro': 'Praça da Sé',
                'complemento': 'lado ímpar',
                'bairro': 'Sé',
                'localidade': 'São Paulo',
                'uf': 'SP',
              },
            ),
          );
        },
      ),
    );

    final address = await CepApi(dio: dio).getAddressByCep('01001-000');

    expect(address.cep, '01001-000');
    expect(address.logradouro, 'Praça da Sé');
    expect(address.bairro, 'Sé');
    expect(address.localidade, 'São Paulo');
    expect(address.uf, 'SP');
  });

  test('rejeita CEP com quantidade inválida de números', () async {
    expect(
      () => CepApi().getAddressByCep('123'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Informe um CEP válido com 8 números.',
        ),
      ),
    );
  });

  test('informa quando o ViaCEP não encontra o endereço', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {'erro': true},
            ),
          );
        },
      ),
    );

    expect(
      () => CepApi(dio: dio).getAddressByCep('00000000'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'CEP não encontrado.',
        ),
      ),
    );
  });
}
