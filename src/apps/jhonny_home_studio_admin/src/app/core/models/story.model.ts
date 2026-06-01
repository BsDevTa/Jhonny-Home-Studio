export interface StudioStory {
  id: string;
  title: string;
  subtitle: string;
  imageUrl?: string | null;
  serviceId?: string | null;
  serviceName?: string | null;
  displayOrder: number;
  isActive: boolean;
  startsAt: string;
  endsAt: string;
  createdAt: string;
  updatedAt?: string | null;
}

export interface CreateStudioStoryRequest {
  title: string;
  subtitle?: string | null;
  imageUrl?: string | null;
  serviceId?: string | null;
  displayOrder: number;
  isActive: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
}

export type UpdateStudioStoryRequest = CreateStudioStoryRequest;
