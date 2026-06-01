import 'package:flutter_test/flutter_test.dart';
import 'package:jhonny_home_studio_app/core/utils/appointment_status_helper.dart';
import 'package:jhonny_home_studio_app/core/utils/whatsapp_helper.dart';

void main() {
  test('normaliza número brasileiro removendo máscara e adicionando DDI', () {
    expect(
      normalizeBrazilianWhatsAppNumber('(71) 99999-9999'),
      '5571999999999',
    );
    expect(
      normalizeBrazilianWhatsAppNumber('+55 (71) 99999-9999'),
      '5571999999999',
    );
  });

  test('monta URL wa.me com mensagem codificada', () {
    final uri = buildWhatsAppUri(
      phoneNumber: '71999999999',
      message: 'Olá, quero confirmar meu horário.',
    );

    expect(uri.toString(), contains('https://wa.me/5571999999999?text='));
    expect(uri.toString(), contains('Ol%C3%A1'));
  });

  test('identifica status que precisam de confirmação pelo WhatsApp', () {
    expect(needsWhatsAppConfirmation('Pending'), isTrue);
    expect(needsWhatsAppConfirmation('WaitingPayment'), isTrue);
    expect(needsWhatsAppConfirmation('Confirmed'), isFalse);
    expect(appointmentStatusLabel('WaitingPayment'), 'Aguardando sinal');
  });
}
