import { DatePipe } from '@angular/common';
import { Component, computed, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { CustomerListModel } from '../../../core/models/customer.model';
import { CustomerService } from '../../../core/services/customer.service';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-customer-list',
  standalone: true,
  imports: [DatePipe, RouterLink, EmptyStateComponent, LoadingComponent, StatusBadgeComponent],
  templateUrl: './customer-list.component.html',
  styleUrl: './customer-list.component.scss'
})
export class CustomerListComponent implements OnInit {
  readonly customers = signal<CustomerListModel[]>([]);
  readonly search = signal('');
  readonly loading = signal(true);
  readonly actionLoadingId = signal('');
  readonly error = signal('');
  readonly filteredCustomers = computed(() => {
    const search = this.normalize(this.search());
    if (!search) {
      return this.customers();
    }

    return this.customers().filter((customer) =>
      [customer.fullName, customer.email, customer.phone ?? ''].some((value) =>
        this.normalize(value).includes(search)
      )
    );
  });

  constructor(private readonly customerService: CustomerService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    this.customerService.getAll().subscribe({
      next: (customers) => {
        this.customers.set(customers);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
  }

  toggleActive(customer: CustomerListModel): void {
    this.actionLoadingId.set(customer.customerId);
    this.error.set('');
    const request = customer.isActive
      ? this.customerService.deactivate(customer.customerId)
      : this.customerService.activate(customer.customerId);

    request.subscribe({
      next: () => {
        this.actionLoadingId.set('');
        this.load();
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.actionLoadingId.set('');
      }
    });
  }

  private normalize(value: string): string {
    return value
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim();
  }
}
