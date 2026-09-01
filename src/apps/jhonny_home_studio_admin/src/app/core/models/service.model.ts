export interface StudioService {
  id: string;
  name: string;
  description?: string | null;
  price: number;
  imageUrl?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface CreateStudioServiceRequest {
  name: string;
  description?: string | null;
  price: number;
  imageUrl?: string | null;
  isActive?: boolean;
}

export interface UpdateStudioServiceRequest extends CreateStudioServiceRequest {
  isActive: boolean;
  removeImage?: boolean;
}
