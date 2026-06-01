import { Component, computed, input } from '@angular/core';

@Component({
  selector: 'app-status-badge',
  standalone: true,
  templateUrl: './status-badge.component.html',
  styleUrl: './status-badge.component.scss'
})
export class StatusBadgeComponent {
  readonly active = input.required<boolean>();
  readonly label = computed(() => (this.active() ? 'Ativo' : 'Inativo'));
}
