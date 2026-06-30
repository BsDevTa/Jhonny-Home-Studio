export interface AppointmentListModel {
  id: string;
  customerName: string;
  customerPhone?: string | null;
  serviceName: string;
  scheduledAt: string;
  status: string;
  servicePriceSnapshot: number;
  estimatedDurationMinutesSnapshot: number;
}

export interface AppointmentModel {
  id: string;
  customerId: string;
  customerName: string;
  customerPhone?: string | null;
  serviceId: string;
  serviceName: string;
  addressId: string;
  addressText: string;
  scheduledAt: string;
  servicePriceSnapshot: number;
  estimatedDurationMinutesSnapshot: number;
  status: string;
  customerNotes?: string | null;
  createdAt: string;
  updatedAt?: string | null;
}

export interface UpdateAppointmentStatusRequest {
  status: string;
  note?: string | null;
}

export interface AppointmentStatusAction {
  status: string;
  label: string;
  note: string;
  buttonClass: 'primary-button' | 'secondary-button' | 'danger-button';
}

export const appointmentStatusOptions = [
  { value: 'Pending', label: 'Pendente', tone: 'warning' },
  { value: 'WaitingPayment', label: 'Aguardando pagamento', tone: 'warning' },
  { value: 'Confirmed', label: 'Confirmado', tone: 'success' },
  { value: 'Rejected', label: 'Recusado', tone: 'danger' },
  { value: 'Canceled', label: 'Cancelado', tone: 'danger' },
  { value: 'Rescheduled', label: 'Reagendado', tone: 'neutral' },
  { value: 'OnTheWay', label: 'A caminho', tone: 'accent' },
  { value: 'InProgress', label: 'Em atendimento', tone: 'accent' },
  { value: 'Completed', label: 'Concluído', tone: 'success' },
  { value: 'NoShow', label: 'Não compareceu', tone: 'danger' }
] as const;

export function getAppointmentStatusLabel(status: string): string {
  return appointmentStatusOptions.find((option) => option.value === status)?.label ?? status;
}

export function getAppointmentStatusTone(status: string): string {
  return appointmentStatusOptions.find((option) => option.value === status)?.tone ?? 'neutral';
}

export function canCancelAppointment(status: string): boolean {
  return !['Canceled', 'Completed', 'Rejected', 'NoShow'].includes(status);
}

export function getAppointmentStatusActions(status: string): AppointmentStatusAction[] {
  switch (status) {
    case 'Pending':
      return [
        {
          status: 'Confirmed',
          label: 'Confirmar',
          note: 'Horário confirmado pelo administrador.',
          buttonClass: 'primary-button'
        },
        {
          status: 'WaitingPayment',
          label: 'Solicitar sinal',
          note: 'Cliente orientado a confirmar o sinal pelo WhatsApp.',
          buttonClass: 'secondary-button'
        },
        {
          status: 'Rejected',
          label: 'Recusar',
          note: 'Agendamento recusado pelo administrador.',
          buttonClass: 'danger-button'
        },
        {
          status: 'Canceled',
          label: 'Cancelar',
          note: 'Agendamento cancelado pelo administrador.',
          buttonClass: 'danger-button'
        }
      ];
    case 'WaitingPayment':
      return [
        {
          status: 'Confirmed',
          label: 'Confirmar sinal',
          note: 'Sinal confirmado pelo administrador.',
          buttonClass: 'primary-button'
        },
        {
          status: 'Rejected',
          label: 'Recusar',
          note: 'Agendamento recusado pelo administrador.',
          buttonClass: 'danger-button'
        },
        {
          status: 'Canceled',
          label: 'Cancelar',
          note: 'Agendamento cancelado pelo administrador.',
          buttonClass: 'danger-button'
        }
      ];
    case 'Confirmed':
      return [
        {
          status: 'InProgress',
          label: 'Iniciar atendimento',
          note: 'Atendimento iniciado pelo administrador.',
          buttonClass: 'primary-button'
        },
        {
          status: 'NoShow',
          label: 'Não compareceu',
          note: 'Não comparecimento registrado pelo administrador.',
          buttonClass: 'secondary-button'
        },
        {
          status: 'Canceled',
          label: 'Cancelar',
          note: 'Agendamento cancelado pelo administrador.',
          buttonClass: 'danger-button'
        }
      ];
    case 'OnTheWay':
      return [
        {
          status: 'InProgress',
          label: 'Iniciar atendimento',
          note: 'Atendimento iniciado pelo administrador.',
          buttonClass: 'primary-button'
        },
        {
          status: 'Canceled',
          label: 'Cancelar',
          note: 'Agendamento cancelado pelo administrador.',
          buttonClass: 'danger-button'
        }
      ];
    case 'InProgress':
      return [
        {
          status: 'Completed',
          label: 'Concluir',
          note: 'Atendimento concluído pelo administrador.',
          buttonClass: 'primary-button'
        }
      ];
    default:
      return [];
  }
}
