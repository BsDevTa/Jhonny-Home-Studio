import 'package:intl/intl.dart';

import '../utils/appointment_status_helper.dart';
import '../utils/whatsapp_helper.dart';

class WhatsAppServiceResult {
  const WhatsAppServiceResult({required this.success, this.errorMessage});

  final bool success;
  final String? errorMessage;
}

class WhatsAppService {
  Future<WhatsAppServiceResult> sendAppointmentStatus({
    required String studioWhatsAppNumber,
    required String customerName,
    required String customerPhone,
    required String serviceName,
    required DateTime? scheduledAt,
    required num servicePrice,
    required String status,
  }) async {
    if (!hasConfiguredWhatsAppNumber(studioWhatsAppNumber)) {
      return const WhatsAppServiceResult(
        success: false,
        errorMessage: 'Configure o WhatsApp do estúdio em Configurações.',
      );
    }

    if (!hasConfiguredWhatsAppNumber(customerPhone)) {
      return const WhatsAppServiceResult(
        success: false,
        errorMessage: 'Telefone do cliente não informado ou inválido.',
      );
    }

    final opened = await openWhatsApp(
      phoneNumber: customerPhone,
      message: _buildAppointmentStatusMessage(
        customerName: customerName,
        serviceName: serviceName,
        scheduledAt: scheduledAt,
        servicePrice: servicePrice,
        status: status,
      ),
    );

    return WhatsAppServiceResult(
      success: opened,
      errorMessage: opened ? null : 'Não foi possível abrir o WhatsApp agora.',
    );
  }

  String _buildAppointmentStatusMessage({
    required String customerName,
    required String serviceName,
    required DateTime? scheduledAt,
    required num servicePrice,
    required String status,
  }) {
    final date = scheduledAt == null
        ? 'Não informada'
        : DateFormat('dd/MM/yyyy').format(scheduledAt.toLocal());
    final time = scheduledAt == null
        ? 'Não informado'
        : DateFormat('HH:mm').format(scheduledAt.toLocal());
    final value = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(servicePrice);
    final name = customerName.trim().isEmpty ? 'cliente' : customerName.trim();
    final service = serviceName.trim().isEmpty
        ? 'Serviço não informado'
        : serviceName.trim();

    return switch (status) {
      'Pending' =>
        '''
Olá, $name 👋

Seu agendamento foi atualizado.

Status:
🟡 ${appointmentStatusLabel(status)}

Serviço:
$service

Data:
$date

Horário:
$time

Em breve entraremos em contato.

Equipe Jhonny Home Studio.''',
      'WaitingPayment' =>
        '''
Olá, $name.

Seu horário está reservado.

Status:
🟡 ${appointmentStatusLabel(status)}

Serviço:
$service

Valor:
$value

Após a confirmação do pagamento seu horário será confirmado.

Equipe Jhonny Home Studio.''',
      'Confirmed' =>
        '''
Olá, $name ✨

Seu agendamento foi confirmado com sucesso.

✅ Status:
${appointmentStatusLabel(status)}

📅 Data:
$date

🕒 Horário:
$time

Serviço:
$service

Estamos ansiosos para recebê-la.

Equipe Jhonny Home Studio.''',
      'Rescheduled' =>
        '''
Olá, $name.

Seu horário foi reagendado.

Nova data:

$date

Novo horário:

$time

Nos vemos em breve.''',
      'InProgress' =>
        '''
Olá, $name.

Seu atendimento acaba de ser iniciado.

Obrigado pela confiança.''',
      'OnTheWay' =>
        '''
Olá, $name.

Estamos aguardando sua chegada.

Até já!''',
      'Completed' =>
        '''
Muito obrigado por escolher o Jhonny Home Studio ❤️

Seu atendimento foi concluído.

Esperamos vê-la novamente em breve.

Se puder, deixe sua avaliação.''',
      'Canceled' =>
        '''
Olá, $name.

Informamos que seu agendamento foi cancelado.

Caso deseje remarcar, estaremos à disposição.''',
      'Rejected' =>
        '''
Olá, $name.

Infelizmente não foi possível confirmar este horário.

Entre em contato conosco para encontrarmos outra disponibilidade.''',
      'NoShow' =>
        '''
Olá, $name.

Notamos que você não compareceu ao horário agendado.

Caso deseje remarcar, teremos prazer em atendê-la novamente.''',
      _ =>
        '''
Olá, $name.

Seu agendamento foi atualizado.

Status:
${appointmentStatusLabel(status)}

Serviço:
$service

Equipe Jhonny Home Studio.''',
    };
  }
}
