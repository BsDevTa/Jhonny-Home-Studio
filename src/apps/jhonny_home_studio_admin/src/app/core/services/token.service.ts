import { Injectable } from '@angular/core';

import { AuthUser } from '../models/auth.model';

@Injectable({ providedIn: 'root' })
export class TokenService {
  private readonly tokenKey = 'jhs_admin_token';
  private readonly userKey = 'jhs_admin_user';

  saveToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  removeToken(): void {
    localStorage.removeItem(this.tokenKey);
  }

  hasToken(): boolean {
    return Boolean(this.getToken());
  }

  saveUser(user: AuthUser): void {
    localStorage.setItem(this.userKey, JSON.stringify(user));
  }

  getUser(): AuthUser | null {
    const user = localStorage.getItem(this.userKey);
    if (!user) {
      return null;
    }

    try {
      return JSON.parse(user) as AuthUser;
    } catch {
      this.removeUser();
      return null;
    }
  }

  removeUser(): void {
    localStorage.removeItem(this.userKey);
  }

  clear(): void {
    this.removeToken();
    this.removeUser();
  }
}
