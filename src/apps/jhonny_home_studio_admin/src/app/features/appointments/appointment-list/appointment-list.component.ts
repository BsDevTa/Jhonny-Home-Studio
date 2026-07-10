import { DatePipe } from '@angular/common';
import { Component, computed, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import {
  AppointmentListModel,
  AppointmentModel,
  appointmentStatusOptions,
  AppointmentStatusAction,
  getAppointmentStatusActions,
} from '../../../core/models/appointment.model';
import { AppointmentService } from '../../../core/services/appointment.service';
import { SettingsService } from '../../../core/services/settings.service';
import { WhatsAppService } from '../../../core/services/whatsapp.service';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { EstimatedDurationPipe } from '../../../shared/pipes/estimated-duration.pipe';
import { PriceFromPipe } from '../../../shared/pipes/price-from.pipe';
import { AppointmentStatusBadgeComponent } from '../widgets/appointment-status-badge/appointment-status-badge.component';

@Component({
  selector: 'app-appointment-list',
  standalone: true,
  imports: [
    DatePipe,
    RouterLink,
    EmptyStateComponent,
    LoadingComponent,
    EstimatedDurationPipe,
    PriceFromPipe,
    AppointmentStatusBadgeComponent,
  ],
  templateUrl: './appointment-list.component.html',
  styleUrl: './appointment-list.component.scss',
})
export class AppointmentListComponent implements OnInit {
  readonly statusOptions = appointmentStatusOptions;
  readonly appointments = signal<AppointmentListModel[]>([]);
  readonly selectedStatus = signal('');
  readonly selectedDate = signal('');
  readonly loading = signal(true);
  readonly actionLoadingId = signal('');
  readonly error = signal('');
  readonly successMessage = signal('');
  readonly pendingWhatsAppAppointment = signal<AppointmentModel | null>(null);
  readonly filteredAppointments = computed(() => {
    const status = this.selectedStatus();
    return status
      ? this.appointments().filter((appointment) => appointment.status === status)
      : this.appointments();
  });

  constructor(
    private readonly appointmentService: AppointmentService,
    private readonly settingsService: SettingsService,
    private readonly whatsAppService: WhatsAppService,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    this.appointmentService.getAll(this.selectedDate() || undefined).subscribe({
      next: (appointments) => {
        this.appointments.set(appointments);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  onStatusChange(event: Event): void {
    this.selectedStatus.set((event.target as HTMLSelectElement).value);
  }

  onDateChange(event: Event): void {
    this.selectedDate.set((event.target as HTMLInputElement).value);
    this.load();
  }

  clearFilters(): void {
    this.selectedStatus.set('');
    this.selectedDate.set('');
    this.load();
  }

  updateStatus(appointment: AppointmentListModel, status: string, note: string): void {
    this.actionLoadingId.set(appointment.id);
    this.error.set('');
    this.successMessage.set('');

    this.appointmentService.updateStatus(appointment.id, status, note).subscribe({
      next: (updatedAppointment) => {
        this.actionLoadingId.set('');
        this.successMessage.set('Status atualizado com sucesso.');
        this.pendingWhatsAppAppointment.set(updatedAppointment);
        this.load();
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.actionLoadingId.set('');
      },
    });
  }

  actionsFor(status: string): AppointmentStatusAction[] {
    return getAppointmentStatusActions(status);
  }

  sendWhatsApp(): void {
    const appointment = this.pendingWhatsAppAppointment();
    if (!appointment) {
      return;
    }

    this.settingsService.getSettings().subscribe({
      next: (settings) => {
        if (!this.whatsAppService.hasConfiguredWhatsAppNumber(settings.whatsAppNumber)) {
          this.error.set('Configure o WhatsApp do estúdio em Configurações.');
          return;
        }

        const opened = this.whatsAppService.sendAppointmentStatus({
          customerName: appointment.customerName,
          customerPhone: appointment.customerPhone,
          serviceName: appointment.serviceName,
          scheduledAt: appointment.scheduledAt,
          servicePrice: appointment.servicePriceSnapshot,
          status: appointment.status,
        });

        if (!opened) {
          this.error.set('Telefone do cliente não informado ou inválido.');
          return;
        }

        this.pendingWhatsAppAppointment.set(null);
        this.successMessage.set('');
      },
      error: (error: Error) => this.error.set(error.message),
    });
  }

  dismissSuccess(): void {
    this.pendingWhatsAppAppointment.set(null);
    this.successMessage.set('');
  }
}
