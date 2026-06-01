import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import {
  AppointmentListModel,
  AppointmentModel,
  UpdateAppointmentStatusRequest
} from '../models/appointment.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class AppointmentService {
  constructor(private readonly api: ApiService) {}

  getAll(date?: string, customerId?: string): Observable<AppointmentListModel[]> {
    const parameters = new URLSearchParams();
    if (date) {
      parameters.set('date', date);
    }
    if (customerId) {
      parameters.set('customerId', customerId);
    }
    const query = parameters.size ? `?${parameters.toString()}` : '';
    return this.api.get<AppointmentListModel[]>(`/admin/appointments${query}`);
  }

  getById(id: string): Observable<AppointmentModel> {
    return this.api.get<AppointmentModel>(`/admin/appointments/${id}`);
  }

  updateStatus(
    id: string,
    status: string,
    note?: string
  ): Observable<AppointmentModel> {
    const request: UpdateAppointmentStatusRequest = {
      status,
      note: note?.trim() || null
    };
    return this.api.patch<AppointmentModel>(`/admin/appointments/${id}/status`, request);
  }
}
