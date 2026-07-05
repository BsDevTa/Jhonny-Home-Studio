import { Component, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';

import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  readonly loading = signal(false);
  readonly error = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly auth: AuthService,
    private readonly router: Router
  ) {
    this.form = this.formBuilder.nonNullable.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]]
    });

    const currentUser = this.auth.currentUser();
    if (currentUser) {
      void this.router.navigate([currentUser.role === 'Admin' ? '/dashboard' : '/home'], {
        replaceUrl: true
      });
    }
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    this.error.set('');

    this.auth.login(this.form.getRawValue()).pipe(finalize(() => this.loading.set(false))).subscribe({
      next: (user) => void this.router.navigate([user.role === 'Admin' ? '/dashboard' : '/home'], { replaceUrl: true }),
      error: (error: Error) => {
        this.error.set(error.message);
      }
    });
  }
}
