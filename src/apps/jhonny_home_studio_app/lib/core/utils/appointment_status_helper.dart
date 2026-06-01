String appointmentStatusLabel(String status) {
  return switch (status.trim().toLowerCase()) {
    'pending' => 'Pendente',
    'waitingpayment' => 'Aguardando sinal',
    'confirmed' => 'Confirmado',
    'rejected' => 'Recusado',
    'canceled' => 'Cancelado',
    'rescheduled' => 'Remarcado',
    'ontheway' => 'A caminho',
    'inprogress' => 'Em atendimento',
    'completed' => 'Concluído',
    'noshow' => 'Não compareceu',
    _ => status,
  };
}

String appointmentStatusGuidance(String status) {
  return switch (status.trim().toLowerCase()) {
    'pending' =>
      'Seu agendamento foi solicitado e está aguardando confirmação do estúdio.',
    'waitingpayment' =>
      'Seu horário está aguardando confirmação do sinal. Fale conosco pelo WhatsApp para finalizar.',
    'confirmed' => 'Seu horário está confirmado. Estamos esperando por você.',
    'rejected' => 'Este agendamento foi recusado pelo estúdio.',
    'canceled' => 'Este agendamento foi cancelado.',
    'rescheduled' => 'Seu atendimento foi remarcado. Confira a nova data.',
    'ontheway' => 'O profissional está a caminho do endereço informado.',
    'inprogress' => 'Seu atendimento está em andamento.',
    'completed' => 'Atendimento concluído.',
    'noshow' => 'Não comparecimento registrado.',
    _ => 'Acompanhe aqui as atualizações do seu atendimento.',
  };
}

bool needsWhatsAppConfirmation(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'pending' || normalized == 'waitingpayment';
}
