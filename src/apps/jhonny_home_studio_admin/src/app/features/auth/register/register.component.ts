import { Component, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, ValidatorFn, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';

import { AuthService } from '../../../core/services/auth.service';

const passwordsMatchValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const password = control.get('password')?.value;
  const confirmPassword = control.get('confirmPassword')?.value;

  return password && confirmPassword && password !== confirmPassword ? { passwordsMismatch: true } : null;
};

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './register.component.html',
  styleUrl: './register.component.scss'
})
export class RegisterComponent {
  readonly loading = signal(false);
  readonly error = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly auth: AuthService,
    private readonly router: Router
  ) {
    this.form = this.formBuilder.nonNullable.group(
      {
        fullName: ['', [Validators.required, Validators.minLength(3)]],
        email: ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required, Validators.minLength(6)]],
        confirmPassword: ['', [Validators.required]]
      },
      { validators: [passwordsMatchValidator] }
    );

    const currentUser = this.auth.currentUser();
    if (currentUser) {
      void this.router.navigate([currentUser.role === 'Admin' ? '/admin/dashboard' : '/home'], {
        replaceUrl: true
      });
    }
  }

  register(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    this.error.set('');

    this.auth.register(this.form.getRawValue()).pipe(finalize(() => this.loading.set(false))).subscribe({
      next: () => void this.router.navigate(['/home'], { replaceUrl: true }),
      error: (error: Error) => {
        this.error.set(error.message);
      }
    });
  }
}
