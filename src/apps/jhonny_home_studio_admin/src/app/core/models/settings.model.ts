export interface StudioSettingsModel {
  id: string;
  studioName: string;
  subtitle: string;
  slogan: string;
  logoUrl?: string | null;
  whatsAppNumber?: string | null;
  instagramUrl?: string | null;
  welcomeTitle?: string | null;
  welcomeMessage?: string | null;
  supportMessage?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface UpdateStudioSettingsRequest {
  studioName: string;
  subtitle: string;
  slogan: string;
  logoUrl?: string | null;
  whatsAppNumber?: string | null;
  instagramUrl?: string | null;
  welcomeTitle?: string | null;
  welcomeMessage?: string | null;
  supportMessage?: string | null;
  isActive: boolean;
}
