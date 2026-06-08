import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { MarketplaceService } from '../../../core/services/marketplace.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-product-category-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './product-category-form.component.html'
})
export class ProductCategoryFormComponent implements OnInit {
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
    private readonly marketplace: MarketplaceService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      name: ['', [Validators.required]],
      description: [''],
      displayOrder: [0],
      isActive: [true]
    });
  }

  ngOnInit(): void {
    if (!this.categoryId) {
      return;
    }
    this.marketplace.getCategoryById(this.categoryId).subscribe({
      next: (category) => {
        this.form.patchValue({
          name: category.name,
          description: category.description ?? '',
          displayOrder: category.displayOrder,
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
    const value = this.form.getRawValue();
    this.saving.set(true);
    this.error.set('');
    const request = {
      name: value.name.trim(),
      description: value.description.trim() || null,
      displayOrder: Number(value.displayOrder),
      isActive: value.isActive
    };
    const call = this.categoryId
      ? this.marketplace.updateCategory(this.categoryId, request)
      : this.marketplace.createCategory(request);
    call.subscribe({
      next: () => void this.router.navigate(['/marketplace/categories']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      }
    });
  }
}
