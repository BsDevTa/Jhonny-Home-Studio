export interface StudioService {
  id: string;
  serviceCategoryId: string;
  serviceCategoryName: string;
  name: string;
  description: string;
  price: number;
  estimatedDurationMinutes: number;
  imageUrl?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface CreateStudioServiceRequest {
  serviceCategoryId: string;
  name: string;
  description: string;
  price: number;
  estimatedDurationMinutes: number;
  imageUrl?: string | null;
}

export interface UpdateStudioServiceRequest extends CreateStudioServiceRequest {
  isActive: boolean;
}
