import { Component, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { ServiceService } from '../../../core/services/service.service';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';

@Component({
  selector: 'app-service-form',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, LoadingComponent],
  templateUrl: './service-form.component.html',
  styleUrl: './service-form.component.scss',
})
export class ServiceFormComponent implements OnInit, OnDestroy {
  private readonly route = inject(ActivatedRoute);
  readonly serviceId = this.route.snapshot.paramMap.get('id');
  readonly editing = Boolean(this.serviceId);
  readonly loading = signal(true);
  readonly saving = signal(false);
  readonly uploadingImage = signal(false);
  readonly error = signal('');
  readonly selectedFileName = signal('');
  readonly imagePreviewUrl = signal('');
  readonly imageRemoved = signal(false);
  readonly form;
  private readonly maxImageSizeBytes = 10 * 1024 * 1024;
  private readonly allowedImageTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
  private readonly allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
  private localPreviewUrl = '';

  constructor(
    private readonly formBuilder: FormBuilder,
    private readonly router: Router,
    private readonly serviceService: ServiceService,
  ) {
    this.form = this.formBuilder.nonNullable.group({
      name: ['', [Validators.required]],
      description: [''],
      price: [0, [Validators.required, Validators.min(0)]],
      imageUrl: [''],
      isActive: [true],
    });
  }

  ngOnInit(): void {
    if (!this.serviceId) {
      this.loading.set(false);
      return;
    }

    this.serviceService.getById(this.serviceId).subscribe({
      next: (service) => {
        this.form.patchValue({
          name: service.name,
          description: this.optionalText(service.description ?? ''),
          price: service.price,
          imageUrl: service.imageUrl ?? '',
          isActive: service.isActive,
        });
        this.imagePreviewUrl.set(service.imageUrl ?? '');
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

    const validationError = this.validateImageFile(file);
    if (validationError) {
      this.error.set(validationError);
      return;
    }

    this.revokeLocalPreview();
    this.localPreviewUrl = URL.createObjectURL(file);
    this.imagePreviewUrl.set(this.localPreviewUrl);
    this.selectedFileName.set(file.name);
    this.uploadingImage.set(true);
    this.error.set('');

    this.serviceService.uploadImage(file).subscribe({
      next: ({ imageUrl }) => {
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
        this.error.set(error.message || 'Não foi possível enviar a imagem.');
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
      this.error.set('Aguarde o upload terminar antes de salvar.');
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

    this.saving.set(true);
    this.error.set('');
    const description = this.optionalText(value.description);
    const payload = {
      name: value.name.trim(),
      description: description || null,
      price: Number(value.price),
      imageUrl: uploadedUrl || null,
      removeImage: this.imageRemoved(),
      isActive: value.isActive,
    };
    const request = this.serviceId
      ? this.serviceService.update(this.serviceId, payload)
      : this.serviceService.create(payload);

    request.subscribe({
      next: () => void this.router.navigate(['/services']),
      error: (error: Error) => {
        this.error.set(error.message);
        this.saving.set(false);
      },
    });
  }

  private optionalText(value: string): string {
    const text = value.trim();
    return text.toLowerCase() === 'null' ? '' : text;
  }

  private validateImageFile(file: File): string {
    const fileName = file.name.toLowerCase();
    const hasAllowedType = this.allowedImageTypes.has(file.type);
    const hasAllowedExtension = this.allowedImageExtensions.some((extension) =>
      fileName.endsWith(extension),
    );

    if (!hasAllowedType && !hasAllowedExtension) {
      return 'Arquivo inválido.';
    }

    if (file.size > this.maxImageSizeBytes) {
      return 'Imagem muito grande.';
    }

    return '';
  }

  private revokeLocalPreview(): void {
    if (!this.localPreviewUrl) {
      return;
    }

    URL.revokeObjectURL(this.localPreviewUrl);
    this.localPreviewUrl = '';
  }
}
