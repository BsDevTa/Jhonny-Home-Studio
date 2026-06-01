import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, computed, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import {
  AppointmentListModel,
  appointmentStatusOptions,
  AppointmentStatusAction,
  getAppointmentStatusActions
} from '../../../core/models/appointment.model';
import { AppointmentService } from '../../../core/services/appointment.service';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { AppointmentStatusBadgeComponent } from '../widgets/appointment-status-badge/appointment-status-badge.component';

@Component({
  selector: 'app-appointment-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    DatePipe,
    RouterLink,
    EmptyStateComponent,
    LoadingComponent,
    AppointmentStatusBadgeComponent
  ],
  templateUrl: './appointment-list.component.html',
  styleUrl: './appointment-list.component.scss'
})
export class AppointmentListComponent implements OnInit {
  readonly statusOptions = appointmentStatusOptions;
  readonly appointments = signal<AppointmentListModel[]>([]);
  readonly selectedStatus = signal('');
  readonly selectedDate = signal('');
  readonly loading = signal(true);
  readonly actionLoadingId = signal('');
  readonly error = signal('');
  readonly filteredAppointments = computed(() => {
    const status = this.selectedStatus();
    return status
      ? this.appointments().filter((appointment) => appointment.status === status)
      : this.appointments();
  });

  constructor(private readonly appointmentService: AppointmentService) {}

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
      }
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

    this.appointmentService.updateStatus(appointment.id, status, note).subscribe({
      next: () => {
        this.actionLoadingId.set('');
        this.load();
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.actionLoadingId.set('');
      }
    });
  }

  actionsFor(status: string): AppointmentStatusAction[] {
    return getAppointmentStatusActions(status);
  }
}
