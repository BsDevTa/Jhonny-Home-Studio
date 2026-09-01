import { Injectable } from '@angular/core';
import { map, Observable } from 'rxjs';

import {
  CreateStudioServiceRequest,
  StudioService,
  UpdateStudioServiceRequest
} from '../models/service.model';
import { resolveMediaUrl } from '../utils/media-url-resolver';
import { ApiService } from './api.service';
import { MediaUploadService } from './media-upload.service';

@Injectable({ providedIn: 'root' })
export class ServiceService {
  constructor(
    private readonly api: ApiService,
    private readonly mediaUpload: MediaUploadService,
  ) {}

  getAll(): Observable<StudioService[]> {
    return this.api
      .get<StudioService[]>('/api/admin/services')
      .pipe(map((services) => services.map((service) => this.normalizeService(service))));
  }

  getById(id: string): Observable<StudioService> {
    return this.api
      .get<StudioService>(`/services/${id}`)
      .pipe(map((service) => this.normalizeService(service)));
  }

  create(request: CreateStudioServiceRequest): Observable<StudioService> {
    return this.api
      .post<StudioService>('/api/admin/services', request)
      .pipe(map((service) => this.normalizeService(service)));
  }

  update(id: string, request: UpdateStudioServiceRequest): Observable<StudioService> {
    return this.api
      .put<StudioService>(`/api/admin/services/${id}`, request)
      .pipe(map((service) => this.normalizeService(service)));
  }

  uploadImage(file: File): Observable<{ imageUrl: string }> {
    return this.mediaUpload.uploadImage(file, 'services');
  }

  activate(id: string): Observable<unknown> {
    return this.api.patch(`/api/admin/services/${id}/activate`);
  }

  deactivate(id: string): Observable<unknown> {
    return this.api.patch(`/api/admin/services/${id}/deactivate`);
  }

  delete(id: string): Observable<unknown> {
    return this.api.delete(`/api/admin/services/${id}`);
  }

  private normalizeService(service: StudioService): StudioService {
    return {
      ...service,
      imageUrl: resolveMediaUrl(service.imageUrl),
    };
  }
}
