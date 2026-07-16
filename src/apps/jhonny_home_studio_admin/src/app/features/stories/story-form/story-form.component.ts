import { Component, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';

import { StudioService } from '../../../core/models/service.model';
import { ServiceService } from '../../../core/services/service.service';
import { StoryService } from '../../../core/services/story.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-story-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './story-form.component.html',
  styleUrl: './story-form.component.scss',
})
export class StoryFormComponent implements OnInit, OnDestroy {
  private readonly route = inject(ActivatedRoute);
  readonly storyId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.storyId);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly uploadingImage = signal(false);
  readonly error = signal('');
  readonly selectedFileName = signal('');
  readonly imagePreviewUrl = signal('');
  readonly imageRemoved = signal(false);
  readonly services = signal<StudioService[]>([]);
  readonly form;
  private localPreviewUrl = '';

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly serviceService: ServiceService,
    private readonly storyService: StoryService,
  ) {
    this.form = this.formBuilder.nonNullable.group({
      title: ['', [Validators.required, Validators.maxLength(160)]],
      subtitle: ['', [Validators.maxLength(280)]],
      imageUrl: ['', [Validators.maxLength(500)]],
      serviceId: [''],
      displayOrder: [0, [Validators.required, Validators.min(0)]],
      startsAt: [''],
      endsAt: [''],
      isActive: [true],
    });
  }

  ngOnInit(): void {
    if (!this.storyId) {
      this.serviceService.getAll().subscribe({
        next: (services) => {
          this.services.set(services);
          this.loading.set(false);
        },
        error: (error: Error) => {
          this.error.set(error.message);
          this.loading.set(false);
        },
      });
      return;
    }

    forkJoin({
      services: this.serviceService.getAll(),
      story: this.storyService.getById(this.storyId),
    }).subscribe({
      next: ({ services, story }) => {
        this.services.set(services);
        this.form.patchValue({
          title: story.title,
          subtitle: story.subtitle,
          imageUrl: story.imageUrl ?? '',
          serviceId: story.serviceId ?? '',
          displayOrder: story.displayOrder,
          startsAt: this.toLocalInput(story.startsAt),
          endsAt: this.toLocalInput(story.endsAt),
          isActive: story.isActive,
        });
        this.imagePreviewUrl.set(story.imageUrl ?? '');
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      },
    });
  }

  ngOnDestroy(): void {
    this.revokeLocalPreview();
  }

  selectImage(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';

    if (!file) {
      return;
    }

    this.revokeLocalPreview();
    this.localPreviewUrl = URL.createObjectURL(file);
    console.debug('Arquivo selecionado:', file.name);
    console.debug('Preview local:', this.localPreviewUrl);
    this.imagePreviewUrl.set(this.localPreviewUrl);
    this.selectedFileName.set(file.name);
    this.uploadingImage.set(true);
    this.error.set('');

    this.storyService.uploadImage(file).subscribe({
      next: ({ imageUrl }) => {
        console.debug('URL definitiva recebida:', imageUrl);
        this.form.controls.imageUrl.setValue(imageUrl);
        this.imageRemoved.set(false);
        this.revokeLocalPreview();
        this.imagePreviewUrl.set(imageUrl);
        this.uploadingImage.set(false);
      },
      error: (error: Error) => {
        this.revokeLocalPreview();
        this.selectedFileName.set('');
        this.imagePreviewUrl.set(this.form.controls.imageUrl.value);
        this.error.set(error.message);
        this.uploadingImage.set(false);
      },
    });
  }

  removeImage(): void {
    if (this.uploadingImage()) {
      return;
    }

    this.revokeLocalPreview();
    this.form.controls.imageUrl.setValue('');
    this.imagePreviewUrl.set('');
    this.selectedFileName.set('');
    this.imageRemoved.set(true);
    this.error.set('');
  }

  submit(): void {
    if (this.uploadingImage()) {
      return;
    }

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    const value = this.form.getRawValue();
    const uploadedUrl = value.imageUrl.trim();
    if (uploadedUrl.startsWith('blob:')) {
      this.error.set('A URL temporária de prévia não pode ser salva. Aguarde o upload concluir.');
      return;
    }

    if (this.selectedFileName() && !uploadedUrl) {
      this.error.set('A imagem foi selecionada, mas a URL do upload está vazia.');
      return;
    }

    if (value.startsAt && value.endsAt && new Date(value.endsAt) <= new Date(value.startsAt)) {
      this.error.set('A data final deve ser posterior à data inicial.');
      return;
    }

    this.saving.set(true);
    this.error.set('');
    const payload = {
      title: value.title.trim(),
      subtitle: value.subtitle.trim() || null,
      imageUrl: uploadedUrl || null,
      removeImage: this.imageRemoved(),
      serviceId: value.serviceId || null,
      displayOrder: Number(value.displayOrder),
      startsAt: this.toIsoOrNull(value.startsAt),
      endsAt: this.toIsoOrNull(value.endsAt),
      isActive: value.isActive,
    };
    console.debug('Payload Story:', JSON.stringify(payload));
    const request = this.storyId
      ? this.storyService.update(this.storyId, payload)
      : this.storyService.create(payload);

    request.subscribe({
      next: () => void this.router.navigate(['/stories']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      },
    });
  }

  private toLocalInput(value: string): string {
    const date = new Date(value);
    const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
    return local.toISOString().slice(0, 16);
  }

  private toIsoOrNull(value: string): string | null {
    return value ? new Date(value).toISOString() : null;
  }

  private revokeLocalPreview(): void {
    if (!this.localPreviewUrl) {
      return;
    }

    URL.revokeObjectURL(this.localPreviewUrl);
    this.localPreviewUrl = '';
  }
}
