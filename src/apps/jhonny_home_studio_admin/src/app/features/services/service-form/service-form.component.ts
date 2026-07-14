import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ServiceService } from '../../../core/services/service.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-service-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './service-form.component.html',
  styleUrl: './service-form.component.scss',
})
export class ServiceFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly serviceId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.serviceId);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly serviceService: ServiceService,
  ) {
    this.form = this.formBuilder.nonNullable.group({
      name: ['', [Validators.required]],
      description: [''],
      price: [0, [Validators.required, Validators.min(0)]],
      imageUrl: [''],
      isActive: [true],
    });
  }

  ngOnInit(): void {
    if (!this.serviceId) {
      this.loading.set(false);
      return;
    }

    this.serviceService.getById(this.serviceId).subscribe({
      next: (service) => {
        this.form.patchValue({
          name: service.name,
          description: this.optionalText(service.description ?? ''),
          price: service.price,
          imageUrl: service.imageUrl ?? '',
          isActive: service.isActive,
        });
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.saving.set(true);
    this.error.set('');
    const value = this.form.getRawValue();
    const description = this.optionalText(value.description);
    const payload = {
      name: value.name.trim(),
      description: description || null,
      price: Number(value.price),
      imageUrl: value.imageUrl.trim() || null,
      isActive: value.isActive,
    };
    console.log('Payload serviço:', payload);
    const request = this.serviceId
      ? this.serviceService.update(this.serviceId, payload)
      : this.serviceService.create(payload);

    request.subscribe({
      next: () => void this.router.navigate(['/services']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      },
    });
  }

  private optionalText(value: string): string {
    const text = value.trim();
    return text.toLowerCase() === 'null' ? '' : text;
  }
}
