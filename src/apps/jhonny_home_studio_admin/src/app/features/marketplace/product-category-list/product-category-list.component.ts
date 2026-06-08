import { Component, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ProductCategoryModel } from '../../../core/models/marketplace.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-product-category-list',
  standalone: true,
  imports: [RouterLink, ConfirmDialogComponent, EmptyStateComponent, LoadingComponent, StatusBadgeComponent],
  templateUrl: './product-category-list.component.html'
})
export class ProductCategoryListComponent implements OnInit {
  readonly categories = signal<ProductCategoryModel[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly categoryToDelete = signal<ProductCategoryModel | null>(null);

  constructor(private readonly marketplace: MarketplaceService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');
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
  }

  toggle(category: ProductCategoryModel): void {
    this.marketplace.toggleCategoryActive(category.id).subscribe({
      next: () => this.load(),
      error: (error: Error) => this.error.set(error.message)
    });
  }

  confirmDelete(): void {
    const category = this.categoryToDelete();
    if (!category) {
      return;
    }
    this.marketplace.deleteCategory(category.id).subscribe({
      next: () => {
        this.categoryToDelete.set(null);
        this.load();
      },
      error: (error: Error) => {
        this.categoryToDelete.set(null);
        this.error.set(error.message);
      }
    });
  }
}
