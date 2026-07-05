import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { catchError, map, Observable, tap, throwError } from 'rxjs';

import { ApiConfig } from '../config/api-config';
import { ApiResponse } from '../models/api-response.model';
import { AuthUser, LoginRequest, RegisterRequest } from '../models/auth.model';
import { TokenService } from './token.service';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly loginUrl = `${ApiConfig.baseUrl}/api/auth/login`;
  private readonly registerUrl = `${ApiConfig.baseUrl}/api/auth/register-customer`;

  constructor(
    private readonly http: HttpClient,
    private readonly tokenService: TokenService
  ) {}

  login(request: LoginRequest): Observable<AuthUser> {
    return this.http.post<ApiResponse<AuthUser>>(this.loginUrl, request).pipe(
      map((response) => this.readAuthResponse(response)),
      tap((user) => this.persistSession(user)),
      catchError((error: unknown) => throwError(() => new Error(this.readError(error))))
    );
  }

  register(request: RegisterRequest): Observable<AuthUser> {
    return this.http.post<ApiResponse<AuthUser>>(this.registerUrl, request).pipe(
      map((response) => this.readAuthResponse(response)),
      tap((user) => this.persistSession(user)),
      catchError((error: unknown) => throwError(() => new Error(this.readError(error))))
    );
  }

  logout(): void {
    this.tokenService.clear();
  }

  isAuthenticated(): boolean {
    return this.tokenService.hasToken() && this.tokenService.getUser() !== null;
  }

  currentUser(): AuthUser | null {
    return this.tokenService.getUser();
  }

  private persistSession(user: AuthUser): void {
    this.tokenService.saveToken(user.token);
    this.tokenService.saveUser(user);
  }

  private readAuthResponse(response: ApiResponse<AuthUser>): AuthUser {
    if (!response.success) {
      throw new Error(this.readMessage(response));
    }

    const user = response.data;

    if (!user.token) {
      throw new Error('Token de autenticação indisponível.');
    }

    return user;
  }

  private readError(error: unknown): string {
    if (error instanceof HttpErrorResponse) {
      if (error.status === 0) {
        return 'Não foi possível conectar à API. Verifique o backend.';
      }

      return this.readMessage(error.error as Partial<ApiResponse<unknown>> | null) || 'Não foi possível entrar.';
    }

    if (error instanceof Error) {
      return error.message;
    }

    return 'Não foi possível entrar.';
  }

  private readMessage(response: Partial<ApiResponse<unknown>> | null): string {
    if (!response) {
      return '';
    }

    return response.errors?.length ? response.errors.join(' ') : response.message ?? '';
  }
}
