import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/utils/service_price_formatter.dart';

void main() {
  test('formata preco de servico como valor inicial', () {
    expect(ServicePriceFormatter.startingAt(600), 'A partir de R\$ 600,00');
    expect(ServicePriceFormatter.startingAt(299.9), 'A partir de R\$ 299,90');
  });
}
