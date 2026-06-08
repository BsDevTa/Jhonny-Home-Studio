import { Routes } from '@angular/router';

import { authGuard } from './core/guards/auth.guard';
import { AdminLayoutComponent } from './layout/admin-layout/admin-layout.component';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/auth/login/login.component').then((component) => component.LoginComponent)
  },
  {
    path: '',
    component: AdminLayoutComponent,
    canActivate: [authGuard],
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard.component').then((component) => component.DashboardComponent)
      },
      {
        path: 'categories',
        loadComponent: () =>
          import('./features/categories/category-list/category-list.component').then((component) => component.CategoryListComponent)
      },
      {
        path: 'categories/new',
        loadComponent: () =>
          import('./features/categories/category-form/category-form.component').then((component) => component.CategoryFormComponent)
      },
      {
        path: 'categories/:id/edit',
        loadComponent: () =>
          import('./features/categories/category-form/category-form.component').then((component) => component.CategoryFormComponent)
      },
      {
        path: 'services',
        loadComponent: () =>
          import('./features/services/service-list/service-list.component').then((component) => component.ServiceListComponent)
      },
      {
        path: 'services/new',
        loadComponent: () =>
          import('./features/services/service-form/service-form.component').then((component) => component.ServiceFormComponent)
      },
      {
        path: 'services/:id/edit',
        loadComponent: () =>
          import('./features/services/service-form/service-form.component').then((component) => component.ServiceFormComponent)
      },
      {
        path: 'appointments',
        loadComponent: () =>
          import('./features/appointments/appointment-list/appointment-list.component').then(
            (component) => component.AppointmentListComponent
          )
      },
      {
        path: 'appointments/:id',
        loadComponent: () =>
          import('./features/appointments/appointment-detail/appointment-detail.component').then(
            (component) => component.AppointmentDetailComponent
          )
      },
      {
        path: 'customers',
        loadComponent: () =>
          import('./features/customers/customer-list/customer-list.component').then(
            (component) => component.CustomerListComponent
          )
      },
      {
        path: 'customers/:id',
        loadComponent: () =>
          import('./features/customers/customer-detail/customer-detail.component').then(
            (component) => component.CustomerDetailComponent
          )
      },
      {
        path: 'stories',
        loadComponent: () =>
          import('./features/stories/story-list/story-list.component').then((component) => component.StoryListComponent)
      },
      {
        path: 'stories/new',
        loadComponent: () =>
          import('./features/stories/story-form/story-form.component').then((component) => component.StoryFormComponent)
      },
      {
        path: 'stories/:id/edit',
        loadComponent: () =>
          import('./features/stories/story-form/story-form.component').then((component) => component.StoryFormComponent)
      },
      {
        path: 'marketplace',
        pathMatch: 'full',
        redirectTo: 'marketplace/products'
      },
      {
        path: 'marketplace/categories',
        loadComponent: () =>
          import('./features/marketplace/product-category-list/product-category-list.component').then(
            (component) => component.ProductCategoryListComponent
          )
      },
      {
        path: 'marketplace/categories/new',
        loadComponent: () =>
          import('./features/marketplace/product-category-form/product-category-form.component').then(
            (component) => component.ProductCategoryFormComponent
          )
      },
      {
        path: 'marketplace/categories/:id/edit',
        loadComponent: () =>
          import('./features/marketplace/product-category-form/product-category-form.component').then(
            (component) => component.ProductCategoryFormComponent
          )
      },
      {
        path: 'marketplace/products',
        loadComponent: () =>
          import('./features/marketplace/product-list/product-list.component').then((component) => component.ProductListComponent)
      },
      {
        path: 'marketplace/products/new',
        loadComponent: () =>
          import('./features/marketplace/product-form/product-form.component').then((component) => component.ProductFormComponent)
      },
      {
        path: 'marketplace/products/:id/edit',
        loadComponent: () =>
          import('./features/marketplace/product-form/product-form.component').then((component) => component.ProductFormComponent)
      },
      {
        path: 'settings',
        loadComponent: () =>
          import('./features/settings/settings-form/settings-form.component').then(
            (component) => component.SettingsFormComponent
          )
      },
      {
        path: 'availability',
        loadComponent: () =>
          import('./features/availability/availability-settings/availability-settings.component').then(
            (component) => component.AvailabilitySettingsComponent
          )
      },
      {
        path: 'availability/blocked-dates/new',
        loadComponent: () =>
          import('./features/availability/blocked-date-form/blocked-date-form.component').then(
            (component) => component.BlockedDateFormComponent
          )
      },
      {
        path: 'availability/blocked-dates/:id/edit',
        loadComponent: () =>
          import('./features/availability/blocked-date-form/blocked-date-form.component').then(
            (component) => component.BlockedDateFormComponent
          )
      },
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];
