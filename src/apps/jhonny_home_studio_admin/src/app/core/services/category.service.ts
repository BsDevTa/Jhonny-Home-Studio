import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import {
  CreateServiceCategoryRequest,
  ServiceCategory,
  UpdateServiceCategoryRequest
} from '../models/category.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class CategoryService {
  constructor(private readonly api: ApiService) {}

  getAll(): Observable<ServiceCategory[]> {
    return this.api.get<ServiceCategory[]>('/admin/service-categories');
  }

  getById(id: string): Observable<ServiceCategory> {
    return this.api.get<ServiceCategory>(`/service-categories/${id}`);
  }

  create(request: CreateServiceCategoryRequest): Observable<ServiceCategory> {
    return this.api.post<ServiceCategory>('/admin/service-categories', request);
  }

  update(id: string, request: UpdateServiceCategoryRequest): Observable<ServiceCategory> {
    return this.api.put<ServiceCategory>(`/admin/service-categories/${id}`, request);
  }

  activate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/service-categories/${id}/activate`);
  }

  deactivate(id: string): Observable<unknown> {
    return this.api.patch(`/admin/service-categories/${id}/deactivate`);
  }

  delete(id: string): Observable<unknown> {
    return this.api.delete(`/admin/service-categories/${id}`);
  }
}
