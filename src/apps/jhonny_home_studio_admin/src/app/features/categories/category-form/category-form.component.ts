import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { CategoryService } from '../../../core/services/category.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-category-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './category-form.component.html',
  styleUrl: './category-form.component.scss'
})
export class CategoryFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly categoryId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.categoryId);
  readonly loading = signal(this.editing);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly categoryService: CategoryService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      name: ['', [Validators.required]],
      description: [''],
      isActive: [true]
    });
  }

  ngOnInit(): void {
    if (!this.categoryId) {
      return;
    }

    this.categoryService.getById(this.categoryId).subscribe({
      next: (category) => {
        this.form.patchValue({
          name: category.name,
          description: category.description ?? '',
          isActive: category.isActive
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
    const description = value.description.trim() || null;
    const request = this.categoryId
      ? this.categoryService.update(this.categoryId, {
          name: value.name.trim(),
          description,
          isActive: value.isActive
        })
      : this.categoryService.create({
          name: value.name.trim(),
          description
        });

    request.subscribe({
      next: () => void this.router.navigate(['/categories']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      }
    });
  }
}
