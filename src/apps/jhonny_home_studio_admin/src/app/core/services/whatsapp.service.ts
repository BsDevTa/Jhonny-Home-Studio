import { Injectable } from '@angular/core';

import { getAppointmentStatusLabel } from '../models/appointment.model';
import { ServicePriceFormatter } from '../utils/service-price-formatter';

export interface AppointmentStatusWhatsAppData {
  customerName: string;
  customerPhone?: string | null;
  serviceName: string;
  scheduledAt: string | Date;
  servicePrice: number;
  status: string;
}

@Injectable({ providedIn: 'root' })
export class WhatsAppService {
  hasConfiguredWhatsAppNumber(phoneNumber?: string | null): boolean {
    return this.normalizeBrazilianWhatsAppNumber(phoneNumber ?? '') !== '';
  }

  sendAppointmentStatus(data: AppointmentStatusWhatsAppData): boolean {
    const phoneNumber = this.normalizeBrazilianWhatsAppNumber(data.customerPhone ?? '');
    if (!phoneNumber) {
      return false;
    }

    const message = this.buildAppointmentStatusMessage(data);
    window.open(
      `https://wa.me/${phoneNumber}?text=${encodeURIComponent(message)}`,
      '_blank',
      'noopener',
    );
    return true;
  }

  private buildAppointmentStatusMessage(data: AppointmentStatusWhatsAppData): string {
    const scheduledAt = new Date(data.scheduledAt);
    const date = Number.isNaN(scheduledAt.getTime())
      ? 'Não informada'
      : new Intl.DateTimeFormat('pt-BR').format(scheduledAt);
    const time = Number.isNaN(scheduledAt.getTime())
      ? 'Não informado'
      : new Intl.DateTimeFormat('pt-BR', { hour: '2-digit', minute: '2-digit' }).format(
          scheduledAt,
        );
    const value = ServicePriceFormatter.startingAt(data.servicePrice);
    const name = data.customerName || 'cliente';
    const service = data.serviceName || 'Serviço não informado';

    switch (data.status) {
      case 'Pending':
        return `Olá, ${name} 👋

Seu agendamento foi atualizado.

Status:
🟡 ${getAppointmentStatusLabel(data.status)}

Serviço:
${service}

Data:
${date}

Horário:
${time}

Em breve entraremos em contato.

Equipe Johnny Home Studio.`;
      case 'WaitingPayment':
        return `Olá, ${name}.

Seu horário está reservado.

Status:
🟡 ${getAppointmentStatusLabel(data.status)}

Serviço:
${service}

Valor:
${value}

Após a confirmação do pagamento seu horário será confirmado.

Equipe Johnny Home Studio.`;
      case 'Confirmed':
        return `Olá, ${name} ✨

Seu agendamento foi confirmado com sucesso.

✅ Status:
${getAppointmentStatusLabel(data.status)}

📅 Data:
${date}

🕒 Horário:
${time}

Serviço:
${service}

Estamos ansiosos para recebê-la.

Equipe Johnny Home Studio.`;
      case 'Rescheduled':
        return `Olá, ${name}.

Seu horário foi reagendado.

Nova data:

${date}

Novo horário:

${time}

Nos vemos em breve.`;
      case 'InProgress':
        return `Olá, ${name}.

Seu atendimento acaba de ser iniciado.

Obrigado pela confiança.`;
      case 'OnTheWay':
        return `Olá, ${name}.

Estamos aguardando sua chegada.

Até já!`;
      case 'Completed':
        return `Muito obrigado por escolher o Johnny Home Studio ❤️

Seu atendimento foi concluído.

Esperamos vê-la novamente em breve.

Se puder, deixe sua avaliação.`;
      case 'Canceled':
        return `Olá, ${name}.

Informamos que seu agendamento foi cancelado.

Caso deseje remarcar, estaremos à disposição.`;
      case 'Rejected':
        return `Olá, ${name}.

Infelizmente não foi possível confirmar este horário.

Entre em contato conosco para encontrarmos outra disponibilidade.`;
      case 'NoShow':
        return `Olá, ${name}.

Notamos que você não compareceu ao horário agendado.

Caso deseje remarcar, teremos prazer em atendê-la novamente.`;
      default:
        return `Olá, ${name}.

Seu agendamento foi atualizado.

Status:
${getAppointmentStatusLabel(data.status)}

Serviço:
${service}

Equipe Johnny Home Studio.`;
    }
  }

  private normalizeBrazilianWhatsAppNumber(phoneNumber: string): string {
    const digits = phoneNumber.replace(/\D/g, '');
    if (digits.length === 11) {
      return `55${digits}`;
    }

    return digits.length === 13 && digits.startsWith('55') ? digits : '';
  }
}
