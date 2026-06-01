import { Component, computed, inject, output } from '@angular/core';

import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-topbar',
  standalone: true,
  templateUrl: './topbar.component.html',
  styleUrl: './topbar.component.scss'
})
export class TopbarComponent {
  private readonly auth = inject(AuthService);
  readonly menuOpened = output<void>();
  readonly user = this.auth.currentUser();
  readonly initials = computed(() =>
    this.user?.fullName
      .split(' ')
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0])
      .join('')
      .toUpperCase() || 'AD'
  );
}
