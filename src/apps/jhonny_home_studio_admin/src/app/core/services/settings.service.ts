import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { StudioSettingsModel, UpdateStudioSettingsRequest } from '../models/settings.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class SettingsService {
  constructor(private readonly api: ApiService) {}

  getSettings(): Observable<StudioSettingsModel> {
    return this.api
      .get<StudioSettingsModel>('/api/admin/settings')
      .pipe(map((settings) => this.normalizeDisplaySettings(settings)));
  }

  updateSettings(request: UpdateStudioSettingsRequest): Observable<StudioSettingsModel> {
    return this.api.put<StudioSettingsModel>('/api/admin/settings', request);
  }

  private normalizeDisplaySettings(settings: StudioSettingsModel): StudioSettingsModel {
    return {
      ...settings,
      studioName: this.normalizeBrandText(settings.studioName),
      subtitle: this.normalizeBrandText(settings.subtitle),
      slogan: this.normalizeBrandText(settings.slogan),
      welcomeTitle: this.normalizeOptionalBrandText(settings.welcomeTitle),
      welcomeMessage: this.normalizeOptionalBrandText(settings.welcomeMessage),
      supportMessage: this.normalizeOptionalBrandText(settings.supportMessage)
    };
  }

  private normalizeOptionalBrandText(value?: string | null): string | null | undefined {
    return value == null ? value : this.normalizeBrandText(value);
  }

  private normalizeBrandText(value: string): string {
    return value.replace(/Jhonny/g, 'Johnny');
  }
}
