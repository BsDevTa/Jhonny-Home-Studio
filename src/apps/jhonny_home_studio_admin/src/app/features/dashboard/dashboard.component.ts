import { Component, OnInit, signal } from '@angular/core';
import { forkJoin } from 'rxjs';

import { AppointmentService } from '../../core/services/appointment.service';
import { CategoryService } from '../../core/services/category.service';
import { CustomerService } from '../../core/services/customer.service';
import { ServiceService } from '../../core/services/service.service';
import { StoryService } from '../../core/services/story.service';
import { LoadingComponent } from '../../shared/components/loading/loading.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [LoadingComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  readonly loading = signal(true);
  readonly error = signal('');
  readonly totalCategories = signal(0);
  readonly totalServices = signal(0);
  readonly activeServices = signal(0);
  readonly totalAppointments = signal(0);
  readonly totalCustomers = signal(0);
  readonly activeStories = signal(0);

  constructor(
    private readonly categories: CategoryService,
    private readonly services: ServiceService,
    private readonly appointments: AppointmentService,
    private readonly customers: CustomerService,
    private readonly stories: StoryService
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    forkJoin({
      categories: this.categories.getAll(),
      services: this.services.getAll(),
      appointments: this.appointments.getAll(),
      customers: this.customers.getAll(),
      stories: this.stories.getAll()
    }).subscribe({
      next: ({ categories, services, appointments, customers, stories }) => {
        this.totalCategories.set(categories.length);
        this.totalServices.set(services.length);
        this.activeServices.set(services.filter((service) => service.isActive).length);
        this.totalAppointments.set(appointments.length);
        this.totalCustomers.set(customers.length);
        this.activeStories.set(stories.filter((story) => story.isActive).length);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }
}
