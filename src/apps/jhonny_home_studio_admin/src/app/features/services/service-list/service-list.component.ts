import { CurrencyPipe } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { StudioService } from '../../../core/models/service.model';
import { ServiceService } from '../../../core/services/service.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-service-list',
  standalone: true,
  imports: [CurrencyPipe, RouterLink, ConfirmDialogComponent, EmptyStateComponent, LoadingComponent, StatusBadgeComponent],
  templateUrl: './service-list.component.html',
  styleUrl: './service-list.component.scss'
})
export class ServiceListComponent implements OnInit {
  readonly services = signal<StudioService[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly serviceToDelete = signal<StudioService | null>(null);

  constructor(private readonly serviceService: ServiceService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    this.serviceService.getAll().subscribe({
      next: (services) => {
        this.services.set(services);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  toggle(service: StudioService): void {
    this.error.set('');
    const request = service.isActive
      ? this.serviceService.deactivate(service.id)
      : this.serviceService.activate(service.id);

    request.subscribe({
      next: () => this.load(),
      error: (error: Error) => this.error.set(error.message)
    });
  }

  confirmDelete(): void {
    const service = this.serviceToDelete();
    if (!service) {
      return;
    }

    this.serviceService.delete(service.id).subscribe({
      next: () => {
        this.serviceToDelete.set(null);
        this.load();
      },
      error: (error: Error) => {
        this.serviceToDelete.set(null);
        this.error.set(error.message);
      }
    });
  }
}
