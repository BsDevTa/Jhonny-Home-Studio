import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';

import { ProductCategoryModel } from '../../../core/models/marketplace.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-product-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './product-form.component.html'
})
export class ProductFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly productId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.productId);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly uploading = signal(false);
  readonly error = signal('');
  readonly categories = signal<ProductCategoryModel[]>([]);
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly marketplace: MarketplaceService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      productCategoryId: ['', [Validators.required]],
      name: ['', [Validators.required]],
      shortDescription: [''],
      description: ['', [Validators.required]],
      price: [0, [Validators.required, Validators.min(0.01)]],
      promotionalPrice: [0],
      stockQuantity: [0],
      displayOrder: [0],
      mainImageUrl: [''],
      isActive: [true],
      isFeatured: [false]
    });
  }

  ngOnInit(): void {
    if (!this.productId) {
      this.marketplace.getCategories().subscribe({
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
      categories: this.marketplace.getCategories(),
      product: this.marketplace.getProductById(this.productId)
    }).subscribe({
      next: ({ categories, product }) => {
        this.categories.set(categories);
        this.form.patchValue({
          productCategoryId: product.productCategoryId,
          name: product.name,
          shortDescription: product.shortDescription ?? '',
          description: product.description,
          price: product.price,
          promotionalPrice: product.promotionalPrice ?? 0,
          stockQuantity: product.stockQuantity ?? 0,
          displayOrder: product.displayOrder,
          mainImageUrl: product.mainImageUrl ?? '',
          isActive: product.isActive,
          isFeatured: product.isFeatured
        });
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  upload(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) {
      return;
    }
    this.uploading.set(true);
    this.error.set('');
    this.marketplace.uploadProductImage(file).pipe(
      finalize(() => this.uploading.set(false))
    ).subscribe({
      next: (result) => {
        this.form.patchValue({ mainImageUrl: result.imageUrl });
      },
      error: (error: Error) => {
        this.error.set(error.message);
      }
    });
  }

  submit(): void {
    if (!this.hasSelectableCategories()) {
      this.error.set('Nenhuma categoria cadastrada. Cadastre uma categoria antes de criar produtos.');
      return;
    }

    if (this.form.invalid || !this.form.controls.productCategoryId.value) {
      this.form.markAllAsTouched();
      this.error.set('Selecione uma categoria para o produto.');
      return;
    }

    const value = this.form.getRawValue();
    const mainImageUrl = value.mainImageUrl.trim() || null;
    const payload = {
      productCategoryId: value.productCategoryId,
      name: value.name.trim(),
      shortDescription: value.shortDescription.trim() || null,
      description: value.description.trim(),
      price: Number(value.price),
      promotionalPrice: Number(value.promotionalPrice) > 0 ? Number(value.promotionalPrice) : null,
      stockQuantity: Number(value.stockQuantity) > 0 ? Number(value.stockQuantity) : null,
      displayOrder: Number(value.displayOrder),
      mainImageUrl,
      isActive: value.isActive,
      isFeatured: value.isFeatured,
      images: mainImageUrl ? [{ imageUrl: mainImageUrl, displayOrder: 0, isMain: true }] : []
    };

    this.saving.set(true);
    this.error.set('');
    const call = this.productId
      ? this.marketplace.updateProduct(this.productId, payload)
      : this.marketplace.createProduct(payload);
    call.pipe(
      finalize(() => this.saving.set(false))
    ).subscribe({
      next: () => void this.router.navigate(['/marketplace/products']),
      error: (error: Error) => {
        this.error.set(this.readSaveError(error));
      }
    });
  }

  visibleCategories(): ProductCategoryModel[] {
    const selectedCategoryId = this.form.controls.productCategoryId.value;
    return this.categories().filter((category) => category.isActive || category.id === selectedCategoryId);
  }

  hasSelectableCategories(): boolean {
    return this.visibleCategories().length > 0;
  }

  private readSaveError(error: Error): string {
    const message = error.message || 'Nao foi possivel salvar o produto.';
    const normalized = message
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase();

    if (normalized.includes('categoria') || normalized.includes('productcategoryid')) {
      return 'Selecione uma categoria para o produto.';
    }

    return message;
  }
}
