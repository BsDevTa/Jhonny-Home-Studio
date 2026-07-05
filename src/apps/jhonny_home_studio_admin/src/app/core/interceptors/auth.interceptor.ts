import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

import { TokenService } from '../services/token.service';

export const authInterceptor: HttpInterceptorFn = (request, next) => {
  const router = inject(Router);
  const tokenService = inject(TokenService);
  const token = tokenService.getToken()?.replace(/^Bearer\s+/i, '').trim();

  const authenticatedRequest = token && !request.headers.has('Authorization')
    ? request.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : request;

  return next(authenticatedRequest).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse && error.status === 401) {
        tokenService.clear();
        void router.navigate(['/login']);
      }

      return throwError(() => error);
    })
  );
};
