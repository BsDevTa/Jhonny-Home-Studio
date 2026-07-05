import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const currentUser = auth.currentUser();
  const allowedRoles = route.data?.['roles'] as string[] | undefined;

  if (!currentUser) {
    return router.createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
  }

  if (!allowedRoles || allowedRoles.includes(currentUser.role)) {
    return true;
  }

  return router.createUrlTree([currentUser.role === 'Admin' ? '/dashboard' : '/home']);
};
