import { Component, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';

import { BlockedDateModel, BusinessHourModel } from '../../../core/models/availability.model';
import { AvailabilityService } from '../../../core/services/availability.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-availability-settings',
  standalone: true,
  imports: [FormsModule, RouterLink, ConfirmDialogComponent, EmptyStateComponent, LoadingComponent],
  templateUrl: './availability-settings.component.html',
  styleUrl: './availability-settings.component.scss'
})
export class AvailabilitySettingsComponent implements OnInit {
  readonly hours = signal<BusinessHourModel[]>([]);
  readonly blockedDates = signal<BlockedDateModel[]>([]);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly success = signal('');
  readonly blockedDateToDelete = signal<BlockedDateModel | null>(null);

  constructor(private readonly availabilityService: AvailabilityService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    forkJoin({
      hours: this.availabilityService.getBusinessHours(),
      blockedDates: this.availabilityService.getBlockedDates()
    }).subscribe({
      next: ({ hours, blockedDates }) => {
        this.hours.set(hours);
        this.blockedDates.set(blockedDates);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  saveHours(): void {
    const validationMessage = this.validateHours();
    if (validationMessage) {
      this.error.set(validationMessage);
      return;
    }

    this.saving.set(true);
    this.error.set('');
    this.success.set('');

    this.availabilityService
      .updateBusinessHours(
        this.hours().map((hour) => ({
          dayOfWeek: hour.dayOfWeek,
          isOpen: hour.isOpen,
          startTime: hour.startTime,
          endTime: hour.endTime,
          slotIntervalMinutes: Number(hour.slotIntervalMinutes)
        }))
      )
      .subscribe({
        next: (hours) => {
          this.hours.set(hours);
          this.success.set('Horários de atendimento salvos com sucesso.');
          this.saving.set(false);
        },
        error: (error: Error) => {
          this.error.set(error.message);
          this.saving.set(false);
        }
      });
  }

  confirmDelete(): void {
    const blockedDate = this.blockedDateToDelete();
    if (!blockedDate) {
      return;
    }

    this.availabilityService.deleteBlockedDate(blockedDate.id).subscribe({
      next: () => {
        this.blockedDateToDelete.set(null);
        this.success.set('Bloqueio excluído com sucesso.');
        this.load();
      },
      error: (error: Error) => {
        this.blockedDateToDelete.set(null);
        this.error.set(error.message);
      }
    });
  }

  formatDate(value: string): string {
    const [year, month, day] = value.split('-');
    return day && month && year ? `${day}/${month}/${year}` : value;
  }

  formatBlockedPeriod(blockedDate: BlockedDateModel): string {
    return blockedDate.isFullDay ? 'Dia inteiro' : `${blockedDate.startTime} às ${blockedDate.endTime}`;
  }

  private validateHours(): string {
    for (const hour of this.hours()) {
      if (hour.slotIntervalMinutes < 15 || hour.slotIntervalMinutes > 120) {
        return `${hour.dayName}: o intervalo deve ficar entre 15 e 120 minutos.`;
      }

      if (hour.isOpen && (!hour.startTime || !hour.endTime || hour.startTime >= hour.endTime)) {
        return `${hour.dayName}: informe um período de atendimento válido.`;
      }
    }

    return '';
  }
}
