import { DatePipe } from '@angular/common';
import { Component, inject, OnInit, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { CustomerDetailModel } from '../../../core/models/customer.model';
import { CustomerService } from '../../../core/services/customer.service';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { EstimatedDurationPipe } from '../../../shared/pipes/estimated-duration.pipe';
import { PriceFromPipe } from '../../../shared/pipes/price-from.pipe';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';
import { AppointmentStatusBadgeComponent } from '../../appointments/widgets/appointment-status-badge/appointment-status-badge.component';

@Component({
  selector: 'app-customer-detail',
  standalone: true,
  imports: [
    DatePipe,
    RouterLink,
    EmptyStateComponent,
    LoadingComponent,
    EstimatedDurationPipe,
    PriceFromPipe,
    StatusBadgeComponent,
    AppointmentStatusBadgeComponent,
  ],
  templateUrl: './customer-detail.component.html',
  styleUrl: './customer-detail.component.scss',
})
export class CustomerDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly customerId = this.route.snapshot.paramMap.get('id') ?? '';
  readonly customer = signal<CustomerDetailModel | null>(null);
  readonly loading = signal(true);
  readonly actionLoading = signal(false);
  readonly error = signal('');

  constructor(private readonly customerService: CustomerService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    this.customerService.getById(this.customerId).subscribe({
      next: (customer) => {
        this.customer.set(customer);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  toggleActive(): void {
    const customer = this.customer();
    if (!customer) {
      return;
    }

    this.actionLoading.set(true);
    this.error.set('');
    const request = customer.isActive
      ? this.customerService.deactivate(customer.customerId)
      : this.customerService.activate(customer.customerId);

    request.subscribe({
      next: () => {
        this.actionLoading.set(false);
        this.load();
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.actionLoading.set(false);
      },
    });
  }
}
