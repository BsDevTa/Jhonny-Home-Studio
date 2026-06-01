import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import {
  CreateStudioServiceRequest,
  StudioService,
  UpdateStudioServiceRequest
} from '../models/service.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class ServiceService {
  constructor(private readonly api: ApiService) {}

  getAll(): Observable<StudioService[]> {
    return this.api.get<StudioService[]>('/admin/services');
  }

  getById(id: string): Observable<StudioService> {
    return this.api.get<StudioService>(`/services/${id}`);
  }

  create(request: CreateStudioServiceRequest): Observable<StudioService> {
    return this.api.post<StudioService>('/admin/services', request);
  }

  update(id: string, request: UpdateStudioServiceRequest): Observable<StudioService> {
    return this.api.put<StudioService>(`/admin/services/${id}`, request);
  }

  activate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/services/${id}/activate`);
  }

  deactivate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/services/${id}/deactivate`);
  }

  delete(id: string): Observable<unknown> {
    return this.api.delete(`/admin/services/${id}`);
  }
}
