import { Component, computed, input } from '@angular/core';

import {
  getAppointmentStatusLabel,
  getAppointmentStatusTone
} from '../../../../core/models/appointment.model';

@Component({
  selector: 'app-appointment-status-badge',
  standalone: true,
  templateUrl: './appointment-status-badge.component.html',
  styleUrl: './appointment-status-badge.component.scss'
})
export class AppointmentStatusBadgeComponent {
  readonly status = input.required<string>();
  readonly label = computed(() => getAppointmentStatusLabel(this.status()));
  readonly tone = computed(() => getAppointmentStatusTone(this.status()));
}
