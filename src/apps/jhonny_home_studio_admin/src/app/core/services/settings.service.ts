import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { StudioSettingsModel, UpdateStudioSettingsRequest } from '../models/settings.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class SettingsService {
  constructor(private readonly api: ApiService) {}

  getSettings(): Observable<StudioSettingsModel> {
    return this.api.get<StudioSettingsModel>('/admin/settings');
  }

  updateSettings(request: UpdateStudioSettingsRequest): Observable<StudioSettingsModel> {
    return this.api.put<StudioSettingsModel>('/admin/settings', request);
  }
}
