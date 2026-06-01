import { Component, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ServiceCategory } from '../../../core/models/category.model';
import { CategoryService } from '../../../core/services/category.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-category-list',
  standalone: true,
  imports: [RouterLink, ConfirmDialogComponent, EmptyStateComponent, LoadingComponent, StatusBadgeComponent],
  templateUrl: './category-list.component.html',
  styleUrl: './category-list.component.scss'
})
export class CategoryListComponent implements OnInit {
  readonly categories = signal<ServiceCategory[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly categoryToDelete = signal<ServiceCategory | null>(null);

  constructor(private readonly categoryService: CategoryService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

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
  }

  toggle(category: ServiceCategory): void {
    this.error.set('');
    const request = category.isActive
      ? this.categoryService.deactivate(category.id)
      : this.categoryService.activate(category.id);

    request.subscribe({
      next: () => this.load(),
      error: (error: Error) => this.error.set(error.message)
    });
  }

  confirmDelete(): void {
    const category = this.categoryToDelete();
    if (!category) {
      return;
    }

    this.categoryService.delete(category.id).subscribe({
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
