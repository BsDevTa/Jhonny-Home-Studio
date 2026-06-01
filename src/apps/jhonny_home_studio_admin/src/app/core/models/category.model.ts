export interface ServiceCategory {
  id: string;
  name: string;
  description?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface CreateServiceCategoryRequest {
  name: string;
  description?: string | null;
}

export interface UpdateServiceCategoryRequest extends CreateServiceCategoryRequest {
  isActive: boolean;
}
