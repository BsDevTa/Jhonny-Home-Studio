import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/utils/service_presentation_formatter.dart';

void main() {
  test('formata preco como valor a partir de com centavos', () {
    expect(
      ServicePresentationFormatter.priceFrom(600),
      'A partir de R\$ 600,00',
    );
  });

  test('formata duracao como estimativa em horas', () {
    expect(
      ServicePresentationFormatter.estimatedDuration(300),
      'Estimativa de 5 horas',
    );
    expect(
      ServicePresentationFormatter.estimatedDuration(90),
      'Estimativa de 1h30',
    );
    expect(
      ServicePresentationFormatter.estimatedDuration(30),
      'Estimativa de 30 minutos',
    );
  });

  test('sanitiza string null literal', () {
    expect(ServicePresentationFormatter.sanitizeNullableText('null'), '');
    expect(ServicePresentationFormatter.sanitizeNullableText('  Null  '), '');
    expect(ServicePresentationFormatter.sanitizeNullableText('texto'), 'texto');
  });
}
