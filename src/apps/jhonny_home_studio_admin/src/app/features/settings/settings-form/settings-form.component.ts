import { Component, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { SettingsService } from '../../../core/services/settings.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-settings-form',
  standalone: true,
  imports: [ReactiveFormsModule, LoadingComponent],
  templateUrl: './settings-form.component.html',
  styleUrl: './settings-form.component.scss'
})
export class SettingsFormComponent implements OnInit {
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly success = signal('');
  readonly form;

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly settingsService: SettingsService
  ) {
    this.form = this.formBuilder.nonNullable.group({
      studioName: ['', [Validators.required, Validators.maxLength(160)]],
      subtitle: ['', [Validators.required, Validators.maxLength(180)]],
      slogan: ['', [Validators.required, Validators.maxLength(280)]],
      logoUrl: ['', [Validators.maxLength(500)]],
      whatsAppNumber: ['', [Validators.maxLength(40)]],
      instagramUrl: ['', [Validators.maxLength(500)]],
      welcomeTitle: ['', [Validators.maxLength(180)]],
      welcomeMessage: ['', [Validators.maxLength(500)]],
      supportMessage: ['', [Validators.maxLength(500)]],
      isActive: [true]
    });
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');
    this.success.set('');

    this.settingsService.getSettings().subscribe({
      next: (settings) => {
        this.form.patchValue({
          studioName: settings.studioName ?? '',
          subtitle: settings.subtitle ?? '',
          slogan: settings.slogan ?? '',
          logoUrl: settings.logoUrl ?? '',
          whatsAppNumber: settings.whatsAppNumber ?? '',
          instagramUrl: settings.instagramUrl ?? '',
          welcomeTitle: settings.welcomeTitle ?? '',
          welcomeMessage: settings.welcomeMessage ?? '',
          supportMessage: settings.supportMessage ?? '',
          isActive: settings.isActive
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

    this.saving.set(true);
    this.error.set('');
    this.success.set('');
    const value = this.form.getRawValue();

    this.settingsService
      .updateSettings({
        studioName: value.studioName.trim(),
        subtitle: value.subtitle.trim(),
        slogan: value.slogan.trim(),
        logoUrl: this.optional(value.logoUrl),
        whatsAppNumber: this.optional(value.whatsAppNumber),
        instagramUrl: this.optional(value.instagramUrl),
        welcomeTitle: this.optional(value.welcomeTitle),
        welcomeMessage: this.optional(value.welcomeMessage),
        supportMessage: this.optional(value.supportMessage),
        isActive: value.isActive
      })
      .subscribe({
        next: () => {
          this.success.set('Configurações salvas com sucesso.');
          this.saving.set(false);
        },
        error: (error: Error) => {
          this.error.set(error.message);
          this.saving.set(false);
        }
      });
  }

  private optional(value: string): string | null {
    return value.trim() || null;
  }
}
