import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { catchError, map, Observable, throwError } from 'rxjs';

import { ApiConfig } from '../config/api-config';
import { ApiResponse } from '../models/api-response.model';

@Injectable({ providedIn: 'root' })
export class ApiService {
  constructor(private readonly http: HttpClient) {}

  get<T>(path: string): Observable<T> {
    return this.handle(this.http.get<ApiResponse<T>>(this.url(path)));
  }

  post<T>(path: string, body: unknown): Observable<T> {
    return this.handle(this.http.post<ApiResponse<T>>(this.url(path), body));
  }

  postForm<T>(path: string, body: FormData): Observable<T> {
    return this.handle(this.http.post<ApiResponse<T>>(this.url(path), body));
  }

  put<T>(path: string, body: unknown): Observable<T> {
    return this.handle(this.http.put<ApiResponse<T>>(this.url(path), body));
  }

  patch<T>(path: string, body: unknown = {}): Observable<T> {
    return this.handle(this.http.patch<ApiResponse<T>>(this.url(path), body));
  }

  delete<T>(path: string): Observable<T> {
    return this.handle(this.http.delete<ApiResponse<T>>(this.url(path)));
  }

  private handle<T>(request: Observable<ApiResponse<T>>): Observable<T> {
    return request.pipe(
      map((response) => {
        if (!response.success) {
          throw new Error(this.readMessage(response));
        }

        return response.data;
      }),
      catchError((error: unknown) => throwError(() => new Error(this.readError(error))))
    );
  }

  private readError(error: unknown): string {
    if (error instanceof HttpErrorResponse) {
      if (error.status === 0) {
        return 'Não foi possível conectar à API. Confirme se o backend está em execução.';
      }

      const response = error.error as Partial<ApiResponse<unknown>> | null;
      return this.readMessage(response) || 'Não foi possível concluir a operação.';
    }

    if (error instanceof Error) {
      return error.message;
    }

    return 'Não foi possível concluir a operação.';
  }

  private readMessage(response: Partial<ApiResponse<unknown>> | null): string {
    if (!response) {
      return '';
    }

    return response.errors?.length ? response.errors.join(' ') : response.message ?? '';
  }

  private url(path: string): string {
    return `${ApiConfig.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
  }
}
