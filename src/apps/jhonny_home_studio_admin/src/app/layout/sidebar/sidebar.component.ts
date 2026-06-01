import { Component, input, output } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';

import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [RouterLink, RouterLinkActive],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent {
  readonly open = input(false);
  readonly closed = output<void>();

  constructor(
    private readonly auth: AuthService,
    private readonly router: Router
  ) {}

  close(): void {
    this.closed.emit();
  }

  logout(): void {
    this.auth.logout();
    void this.router.navigate(['/login']);
  }
}
