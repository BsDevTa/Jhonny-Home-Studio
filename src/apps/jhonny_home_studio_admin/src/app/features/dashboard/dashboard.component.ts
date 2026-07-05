import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit, signal } from '@angular/core';
import { forkJoin, map, Observable } from 'rxjs';

import { ApiConfig } from '../../core/config/api-config';
import { ApiResponse } from '../../core/models/api-response.model';
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

  constructor(private readonly http: HttpClient) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    forkJoin({
      categories: this.fetchCollection<{ id: string; isActive?: boolean }>('/api/admin/service-categories'),
      services: this.fetchCollection<{ id: string; isActive: boolean }>('/api/admin/services'),
      appointments: this.fetchCollection<{ id: string }>('/api/admin/appointments'),
      customers: this.fetchCollection<{ id: string }>('/api/admin/customers'),
      stories: this.fetchCollection<{ id: string; isActive: boolean }>('/api/admin/stories')
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
      error: (error: unknown) => {
        console.error('Erro detalhado:', error);
        this.error.set(this.readErrorMessage(error));
        this.loading.set(false);
      }
    });
  }

  private fetchCollection<T>(path: string): Observable<T[]> {
    return this.http.get<ApiResponse<T[]>>(this.url(path)).pipe(map((response) => response.data ?? []));
  }

  private readErrorMessage(error: unknown): string {
    if (error instanceof HttpErrorResponse) {
      if (error.status === 0) {
        return 'Falha de comunicação com a API. Verifique CORS, rede ou backend indisponível.';
      }

      if (error.status === 401) {
        return 'Sessão inválida ou token ausente. Faça login novamente.';
      }

      if (error.status === 403) {
        return 'Acesso negado para este recurso.';
      }

      return error.message || 'Não foi possível concluir a operação.';
    }

    if (error instanceof Error) {
      return error.message;
    }

    return 'Não foi possível concluir a operação.';
  }

  private url(path: string): string {
    return `${ApiConfig.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
  }
}
