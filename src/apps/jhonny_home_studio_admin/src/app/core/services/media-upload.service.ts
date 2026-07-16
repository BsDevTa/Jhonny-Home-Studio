import { Injectable } from '@angular/core';
import { map, Observable } from 'rxjs';

import { resolveMediaUrl } from '../utils/media-url-resolver';
import { ApiService } from './api.service';

export type MediaUploadFolder = 'stories' | 'services' | 'products';

export interface MediaUploadResponse {
  imageUrl: string;
  mediaUrl: string;
  url: string;
  relativePath?: string;
  fileName?: string;
  contentType?: string;
  sizeBytes?: number;
  mediaType?: string;
  storageProvider?: string;
}

@Injectable({ providedIn: 'root' })
export class MediaUploadService {
  constructor(private readonly api: ApiService) {}

  uploadImage(file: File, folder: MediaUploadFolder): Observable<MediaUploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('folder', folder);

    return this.api
      .postForm<Record<string, unknown>>('/api/admin/stories/upload-media', formData)
      .pipe(map((response) => this.normalizeResponse(response)));
  }

  private normalizeResponse(response: Record<string, unknown>): MediaUploadResponse {
    const uploadedUrl = this.readUploadUrl(response);
    if (!uploadedUrl) {
      throw new Error('Upload concluído, mas a API não retornou a URL da imagem.');
    }

    return {
      imageUrl: uploadedUrl,
      mediaUrl: uploadedUrl,
      url: uploadedUrl,
      relativePath: this.readOptionalString(response, 'relativePath'),
      fileName: this.readOptionalString(response, 'fileName'),
      contentType: this.readOptionalString(response, 'contentType'),
      sizeBytes: this.readOptionalNumber(response, 'sizeBytes'),
      mediaType: this.readOptionalString(response, 'mediaType'),
      storageProvider: this.readOptionalString(response, 'storageProvider'),
    };
  }

  private readUploadUrl(response: Record<string, unknown>): string {
    for (const key of ['imageUrl', 'mediaUrl', 'url', 'fileUrl']) {
      const value = response[key];
      if (typeof value === 'string' && value.trim()) {
        return resolveMediaUrl(value);
      }
    }

    return '';
  }

  private readOptionalString(response: Record<string, unknown>, key: string): string | undefined {
    const value = response[key];
    return typeof value === 'string' && value.trim() ? value.trim() : undefined;
  }

  private readOptionalNumber(response: Record<string, unknown>, key: string): number | undefined {
    const value = response[key];
    return typeof value === 'number' ? value : undefined;
  }
}
