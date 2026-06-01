import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import {
  BlockedDateModel,
  BusinessHourModel,
  UpdateBusinessHourRequest,
  UpsertBlockedDateRequest
} from '../models/availability.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class AvailabilityService {
  constructor(private readonly api: ApiService) {}

  getBusinessHours(): Observable<BusinessHourModel[]> {
    return this.api.get<BusinessHourModel[]>('/admin/availability/business-hours');
  }

  updateBusinessHours(hours: UpdateBusinessHourRequest[]): Observable<BusinessHourModel[]> {
    return this.api.put<BusinessHourModel[]>('/admin/availability/business-hours', hours);
  }

  getBlockedDates(): Observable<BlockedDateModel[]> {
    return this.api.get<BlockedDateModel[]>('/admin/availability/blocked-dates');
  }

  getBlockedDateById(id: string): Observable<BlockedDateModel> {
    return this.api.get<BlockedDateModel>(`/admin/availability/blocked-dates/${id}`);
  }

  createBlockedDate(request: UpsertBlockedDateRequest): Observable<BlockedDateModel> {
    return this.api.post<BlockedDateModel>('/admin/availability/blocked-dates', request);
  }

  updateBlockedDate(id: string, request: UpsertBlockedDateRequest): Observable<BlockedDateModel> {
    return this.api.put<BlockedDateModel>(`/admin/availability/blocked-dates/${id}`, request);
  }

  deleteBlockedDate(id: string): Observable<unknown> {
    return this.api.delete(`/admin/availability/blocked-dates/${id}`);
  }
}
