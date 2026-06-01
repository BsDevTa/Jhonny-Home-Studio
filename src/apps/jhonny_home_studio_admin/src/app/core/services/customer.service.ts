import { Injectable } from '@angular/core';
import { forkJoin, map, Observable } from 'rxjs';

import {
  CustomerAddressModel,
  CustomerDetailModel,
  CustomerListModel,
  CustomerProfileModel
} from '../models/customer.model';
import { ApiService } from './api.service';
import { AppointmentService } from './appointment.service';

@Injectable({ providedIn: 'root' })
export class CustomerService {
  constructor(
    private readonly api: ApiService,
    private readonly appointments: AppointmentService
  ) {}

  getAll(): Observable<CustomerListModel[]> {
    return this.api.get<CustomerListModel[]>('/admin/customers');
  }

  getById(id: string): Observable<CustomerDetailModel> {
    return forkJoin({
      profile: this.api.get<CustomerProfileModel>(`/admin/customers/${id}`),
      addresses: this.api.get<CustomerAddressModel[]>(`/admin/customers/${id}/addresses`),
      appointments: this.appointments.getAll(undefined, id)
    }).pipe(
      map(({ profile, addresses, appointments }) => ({
        ...profile,
        addresses: addresses ?? [],
        appointments: appointments ?? []
      }))
    );
  }

  activate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/customers/${id}/activate`);
  }

  deactivate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/customers/${id}/deactivate`);
  }
}
