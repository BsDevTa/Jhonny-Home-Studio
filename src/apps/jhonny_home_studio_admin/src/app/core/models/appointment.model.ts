export interface AppointmentListModel {
  id: string;
  customerName: string;
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

export const appointmentStatusOptions = [
  { value: 'Pending', label: 'Pendente', tone: 'warning' },
  { value: 'WaitingPayment', label: 'Aguardando sinal', tone: 'warning' },
  { value: 'Confirmed', label: 'Confirmado', tone: 'success' },
  { value: 'Rejected', label: 'Recusado', tone: 'danger' },
  { value: 'Canceled', label: 'Cancelado', tone: 'danger' },
  { value: 'Rescheduled', label: 'Remarcado', tone: 'neutral' },
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
