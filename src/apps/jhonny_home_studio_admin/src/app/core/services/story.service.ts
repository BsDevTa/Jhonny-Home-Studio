import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { CreateStudioStoryRequest, StudioStory, UpdateStudioStoryRequest } from '../models/story.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class StoryService {
  constructor(private readonly api: ApiService) {}

  getAll(): Observable<StudioStory[]> {
    return this.api.get<StudioStory[]>('/admin/stories');
  }

  getById(id: string): Observable<StudioStory> {
    return this.api.get<StudioStory>(`/admin/stories/${id}`);
  }

  uploadImage(file: File): Observable<{ imageUrl: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api.post<{ imageUrl: string }>('/admin/stories/upload-image', formData);
  }

  create(request: CreateStudioStoryRequest): Observable<StudioStory> {
    return this.api.post<StudioStory>('/admin/stories', request);
  }

  update(id: string, request: UpdateStudioStoryRequest): Observable<StudioStory> {
    return this.api.put<StudioStory>(`/admin/stories/${id}`, request);
  }

  toggleActive(id: string): Observable<StudioStory> {
    return this.api.patch<StudioStory>(`/admin/stories/${id}/toggle-active`);
  }

  delete(id: string): Observable<unknown> {
    return this.api.delete(`/admin/stories/${id}`);
  }
}
