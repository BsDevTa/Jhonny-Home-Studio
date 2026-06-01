import { Component, inject, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AvailabilityService } from '../../../core/services/availability.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-blocked-date-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './blocked-date-form.component.html',
  styleUrl: './blocked-date-form.component.scss'
})
export class BlockedDateFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  readonly blockedDateId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.blockedDateId);
  readonly loading = signal(this.editing);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly availabilityService: AvailabilityService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      date: ['', [Validators.required]],
      reason: ['', [Validators.required, Validators.maxLength(180)]],
      isFullDay: [true],
      startTime: [''],
      endTime: ['']
    });
  }

  ngOnInit(): void {
    if (!this.blockedDateId) {
      return;
    }

    this.availabilityService.getBlockedDateById(this.blockedDateId).subscribe({
      next: (blockedDate) => {
        this.form.patchValue({
          date: blockedDate.date,
          reason: blockedDate.reason,
          isFullDay: blockedDate.isFullDay,
          startTime: blockedDate.startTime ?? '',
          endTime: blockedDate.endTime ?? ''
        });
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const value = this.form.getRawValue();
    if (!value.isFullDay && (!value.startTime || !value.endTime || value.startTime >= value.endTime)) {
      this.error.set('Informe um intervalo válido para o bloqueio parcial.');
      return;
    }

    this.saving.set(true);
    this.error.set('');
    const payload = {
      date: value.date,
      reason: value.reason.trim(),
      isFullDay: value.isFullDay,
      startTime: value.isFullDay ? null : value.startTime,
      endTime: value.isFullDay ? null : value.endTime
    };
    const request = this.blockedDateId
      ? this.availabilityService.updateBlockedDate(this.blockedDateId, payload)
      : this.availabilityService.createBlockedDate(payload);

    request.subscribe({
      next: () => void this.router.navigate(['/availability']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      }
    });
  }
}
