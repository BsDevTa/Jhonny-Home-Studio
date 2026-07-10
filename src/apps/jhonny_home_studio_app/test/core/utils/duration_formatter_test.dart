import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/utils/duration_formatter.dart';

void main() {
  test('formata minutos em horas estimadas para cliente', () {
    expect(DurationFormatter.format(30), '30 minutos');
    expect(DurationFormatter.format(60), '1 hora');
    expect(DurationFormatter.format(90), '1h30');
    expect(DurationFormatter.format(120), '2 horas');
    expect(DurationFormatter.format(150), '2h30');
    expect(DurationFormatter.format(300), '5 horas');
    expect(DurationFormatter.format(330), '5h30');
    expect(DurationFormatter.estimated(300), 'Estimativa de 5 horas');
    expect(DurationFormatter.estimated(0), 'Tempo a confirmar');
  });
}
