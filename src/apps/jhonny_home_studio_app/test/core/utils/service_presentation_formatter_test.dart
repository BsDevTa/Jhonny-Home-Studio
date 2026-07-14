import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/utils/service_presentation_formatter.dart';

void main() {
  test('formata preco como valor a partir de com centavos', () {
    expect(
      ServicePresentationFormatter.priceFrom(600),
      'A partir de R\$ 600,00',
    );
  });

  test('sanitiza string null literal', () {
    expect(ServicePresentationFormatter.sanitizeNullableText('null'), '');
    expect(ServicePresentationFormatter.sanitizeNullableText('  Null  '), '');
    expect(ServicePresentationFormatter.sanitizeNullableText('texto'), 'texto');
  });
}
