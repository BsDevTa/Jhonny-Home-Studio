import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';

import { ServiceCategory } from '../../../core/models/category.model';
import { CategoryService } from '../../../core/services/category.service';
import { ServiceService } from '../../../core/services/service.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-service-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './service-form.component.html',
  styleUrl: './service-form.component.scss'
})
export class ServiceFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly serviceId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.serviceId);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly categories = signal<ServiceCategory[]>([]);
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly categoryService: CategoryService,
    private readonly serviceService: ServiceService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      serviceCategoryId: ['', [Validators.required]],
      name: ['', [Validators.required]],
      description: ['', [Validators.required]],
      price: [0, [Validators.required, Validators.min(0.01)]],
      estimatedDurationMinutes: [60, [Validators.required, Validators.min(1)]],
      imageUrl: [''],
      isActive: [true]
    });
  }

  ngOnInit(): void {
    if (!this.serviceId) {
      this.categoryService.getAll().subscribe({
        next: (categories) => {
          this.categories.set(categories);
          this.loading.set(false);
        },
        error: (error: Error) => {
          this.error.set(error.message);
          this.loading.set(false);
        }
      });
      return;
    }

    forkJoin({
      categories: this.categoryService.getAll(),
      service: this.serviceService.getById(this.serviceId)
    }).subscribe({
      next: ({ categories, service }) => {
        this.categories.set(categories);
        this.form.patchValue({
          serviceCategoryId: service.serviceCategoryId,
          name: service.name,
          description: service.description,
          price: service.price,
          estimatedDurationMinutes: service.estimatedDurationMinutes,
          imageUrl: service.imageUrl ?? '',
          isActive: service.isActive
        });
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
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
    const payload = {
      serviceCategoryId: value.serviceCategoryId,
      name: value.name.trim(),
      description: value.description.trim(),
      price: Number(value.price),
      estimatedDurationMinutes: Number(value.estimatedDurationMinutes),
      imageUrl: value.imageUrl.trim() || null
    };
    const request = this.serviceId
      ? this.serviceService.update(this.serviceId, { ...payload, isActive: value.isActive })
      : this.serviceService.create(payload);

    request.subscribe({
      next: () => void this.router.navigate(['/services']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      }
    });
  }
}
