import { DatePipe } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import {
  AppointmentModel,
  appointmentStatusOptions,
  AppointmentStatusAction,
  getAppointmentStatusLabel,
  getAppointmentStatusActions,
} from '../../../core/models/appointment.model';
import { AppointmentService } from '../../../core/services/appointment.service';
import { SettingsService } from '../../../core/services/settings.service';
import { WhatsAppService } from '../../../core/services/whatsapp.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { EstimatedDurationPipe } from '../../../shared/pipes/estimated-duration.pipe';
import { PriceFromPipe } from '../../../shared/pipes/price-from.pipe';
import { AppointmentStatusBadgeComponent } from '../widgets/appointment-status-badge/appointment-status-badge.component';

@Component({
  selector: 'app-appointment-detail',
  standalone: true,
  imports: [
    DatePipe,
    FormsModule,
    RouterLink,
    LoadingComponent,
    EstimatedDurationPipe,
    PriceFromPipe,
    AppointmentStatusBadgeComponent,
  ],
  templateUrl: './appointment-detail.component.html',
  styleUrl: './appointment-detail.component.scss',
})
export class AppointmentDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly appointmentId = this.route.snapshot.paramMap.get('id') ?? '';
  readonly statusOptions = appointmentStatusOptions;
  readonly appointment = signal<AppointmentModel | null>(null);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly successMessage = signal('');
  readonly lastWhatsAppStatus = signal('');
  selectedStatus = '';
  note = '';

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

    this.appointmentService.getById(this.appointmentId).subscribe({
      next: (appointment) => {
        this.appointment.set(appointment);
        this.selectedStatus = appointment.status;
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  updateStatus(): void {
    if (!this.selectedStatus) {
      return;
    }

    this.saveStatus(this.selectedStatus, this.note);
  }

  applyQuickAction(action: AppointmentStatusAction): void {
    this.selectedStatus = action.status;
    this.saveStatus(action.status, this.note.trim() || action.note);
  }

  actionsFor(status: string): AppointmentStatusAction[] {
    return getAppointmentStatusActions(status);
  }

  private saveStatus(status: string, note: string): void {
    this.saving.set(true);
    this.error.set('');
    this.successMessage.set('');

    this.appointmentService.updateStatus(this.appointmentId, status, note).subscribe({
      next: (appointment) => {
        this.appointment.set(appointment);
        this.selectedStatus = appointment.status;
        this.note = '';
        this.saving.set(false);
        this.successMessage.set('Status atualizado com sucesso.');
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      },
    });
  }

  sendWhatsApp(statusOverride?: string): void {
    const appointment = this.appointment();
    if (!appointment) {
      return;
    }

    const statusToSend = statusOverride || appointment.status;

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
          status: statusToSend,
        });

        if (!opened) {
          this.error.set('Telefone do cliente não informado ou inválido.');
          return;
        }

        this.lastWhatsAppStatus.set(statusToSend);
        this.successMessage.set('');
      },
      error: (error: Error) => this.error.set(error.message),
    });
  }

  lastWhatsAppStatusLabel(): string {
    const status = this.lastWhatsAppStatus();
    return status ? getAppointmentStatusLabel(status) : '-';
  }

  resendWhatsApp(): void {
    const status = this.lastWhatsAppStatus();
    if (status) {
      this.sendWhatsApp(status);
    }
  }
}
