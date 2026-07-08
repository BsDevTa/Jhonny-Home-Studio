import { CurrencyPipe } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { getProductDisplayImageUrl, ProductModel } from '../../../core/models/marketplace.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-product-list',
  standalone: true,
  imports: [
    CurrencyPipe,
    RouterLink,
    ConfirmDialogComponent,
    EmptyStateComponent,
    LoadingComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './product-list.component.html',
})
export class ProductListComponent implements OnInit {
  readonly products = signal<ProductModel[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly productToDelete = signal<ProductModel | null>(null);

  constructor(private readonly marketplace: MarketplaceService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');
    this.marketplace.getProducts().subscribe({
      next: (products) => {
        this.products.set(products);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  toggle(product: ProductModel): void {
    this.marketplace.toggleProductActive(product.id).subscribe({
      next: () => this.load(),
      error: (error: Error) => this.error.set(error.message),
    });
  }

  confirmDelete(): void {
    const product = this.productToDelete();
    if (!product) {
      return;
    }
    this.marketplace.deleteProduct(product.id).subscribe({
      next: () => {
        this.productToDelete.set(null);
        this.load();
      },
      error: (error: Error) => {
        this.productToDelete.set(null);
        this.error.set(error.message);
      },
    });
  }

  displayImageUrl(product: ProductModel): string {
    return getProductDisplayImageUrl(product);
  }
}
