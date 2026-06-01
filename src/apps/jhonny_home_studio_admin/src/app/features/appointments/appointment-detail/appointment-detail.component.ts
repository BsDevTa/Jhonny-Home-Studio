import { CurrencyPipe, DatePipe } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import {
  AppointmentModel,
  appointmentStatusOptions
} from '../../../core/models/appointment.model';
import { AppointmentService } from '../../../core/services/appointment.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { AppointmentStatusBadgeComponent } from '../widgets/appointment-status-badge/appointment-status-badge.component';

@Component({
  selector: 'app-appointment-detail',
  standalone: true,
  imports: [CurrencyPipe, DatePipe, FormsModule, RouterLink, LoadingComponent, AppointmentStatusBadgeComponent],
  templateUrl: './appointment-detail.component.html',
  styleUrl: './appointment-detail.component.scss'
})
export class AppointmentDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly appointmentId = this.route.snapshot.paramMap.get('id') ?? '';
  readonly statusOptions = appointmentStatusOptions;
  readonly appointment = signal<AppointmentModel | null>(null);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  selectedStatus = '';
  note = '';

  constructor(
    private readonly appointmentService: AppointmentService
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
      }
    });
  }

  updateStatus(): void {
    if (!this.selectedStatus) {
      return;
    }

    this.saving.set(true);
    this.error.set('');

    this.appointmentService.updateStatus(this.appointmentId, this.selectedStatus, this.note).subscribe({
      next: (appointment) => {
        this.appointment.set(appointment);
        this.selectedStatus = appointment.status;
        this.note = '';
        this.saving.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      }
    });
  }
}
