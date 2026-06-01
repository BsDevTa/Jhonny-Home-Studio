import { Injectable } from '@angular/core';
import { map, Observable, tap } from 'rxjs';

import { AuthUser, LoginRequest } from '../models/auth.model';
import { ApiService } from './api.service';
import { TokenService } from './token.service';

@Injectable({ providedIn: 'root' })
export class AuthService {
  constructor(
    private readonly api: ApiService,
    private readonly tokenService: TokenService
  ) {}

  login(request: LoginRequest): Observable<AuthUser> {
    return this.api.post<AuthUser>('/auth/login', request).pipe(
      map((user) => {
        if (user.role !== 'Admin') {
          throw new Error('Este acesso é exclusivo para administradores.');
        }

        return user;
      }),
      tap((user) => {
        this.tokenService.saveToken(user.token);
        this.tokenService.saveUser(user);
      })
    );
  }

  logout(): void {
    this.tokenService.clear();
  }

  isAuthenticated(): boolean {
    return this.tokenService.hasToken() && this.tokenService.getUser()?.role === 'Admin';
  }

  currentUser(): AuthUser | null {
    return this.tokenService.getUser();
  }
}
