import { Injectable } from '@angular/core';
import { map, Observable } from 'rxjs';

import {
  CreateStudioStoryRequest,
  StudioStory,
  UpdateStudioStoryRequest,
} from '../models/story.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class StoryService {
  constructor(private readonly api: ApiService) {}

  getAll(): Observable<StudioStory[]> {
    return this.api.get<StudioStory[]>('/api/admin/stories');
  }

  getById(id: string): Observable<StudioStory> {
    return this.api.get<StudioStory>(`/api/admin/stories/${id}`);
  }

  uploadImage(file: File): Observable<{ imageUrl: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api
      .postForm<Record<string, unknown>>('/api/admin/stories/upload-media', formData)
      .pipe(
        map((response) => {
          console.debug('Resposta completa upload-media:', response);
          const uploadedUrl = this.readUploadUrl(response);
          console.debug('URL definitiva recebida:', uploadedUrl);
          if (!uploadedUrl) {
            throw new Error('Upload concluído, mas a API não retornou a URL da imagem.');
          }

          return { imageUrl: uploadedUrl };
        }),
      );
  }

  create(request: CreateStudioStoryRequest): Observable<StudioStory> {
    return this.api.post<StudioStory>('/api/admin/stories', request);
  }

  update(id: string, request: UpdateStudioStoryRequest): Observable<StudioStory> {
    return this.api.put<StudioStory>(`/api/admin/stories/${id}`, request);
  }

  toggleActive(id: string): Observable<StudioStory> {
    return this.api.patch<StudioStory>(`/api/admin/stories/${id}/toggle-active`);
  }

  delete(id: string): Observable<unknown> {
    return this.api.delete(`/api/admin/stories/${id}`);
  }

  private readUploadUrl(response: Record<string, unknown>): string {
    for (const key of ['imageUrl', 'mediaUrl', 'url', 'fileUrl']) {
      const value = response[key];
      if (typeof value === 'string' && value.trim()) {
        return value.trim();
      }
    }

    return '';
  }
}
