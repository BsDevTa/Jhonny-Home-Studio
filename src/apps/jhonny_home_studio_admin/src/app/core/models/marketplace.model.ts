import { ApiConfig } from '../config/api-config';

export interface ProductCategoryModel {
  id: string;
  name: string;
  description?: string | null;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface ProductImageModel {
  id: string;
  productId: string;
  imageUrl: string;
  displayOrder: number;
  isMain: boolean;
  createdAt: string;
}

export interface ProductModel {
  id: string;
  productCategoryId: string;
  productCategoryName: string;
  name: string;
  description: string;
  shortDescription?: string | null;
  price: number;
  promotionalPrice?: number | null;
  mainImageUrl?: string | null;
  isActive: boolean;
  isFeatured: boolean;
  displayOrder: number;
  stockQuantity?: number | null;
  images: ProductImageModel[];
  createdAt: string;
  updatedAt?: string | null;
}

export function resolveUrl(value?: string | null): string {
  const url = (value ?? '').trim();
  if (!url) {
    return '';
  }

  try {
    const parsed = new URL(url);
    if (parsed.protocol) {
      return url;
    }
  } catch {
    // Treat as relative below.
  }

  const normalizedPath = url.startsWith('/') ? url : `/${url}`;
  return `${ApiConfig.baseUrl}${normalizedPath}`;
}

export function getProductDisplayImageUrl(
  product: Pick<ProductModel, 'mainImageUrl' | 'images'>,
): string {
  const mainImage = resolveUrl(product.mainImageUrl);
  if (mainImage) {
    return mainImage;
  }

  const mainImageFromList = product.images.find((image) => image.isMain)?.imageUrl ?? '';
  if (mainImageFromList.trim()) {
    return resolveUrl(mainImageFromList);
  }

  return resolveUrl(product.images[0]?.imageUrl);
}

export interface UpsertProductCategoryRequest {
  name: string;
  description?: string | null;
  displayOrder: number;
  isActive: boolean;
}

export interface UpsertProductRequest {
  productCategoryId: string;
  name: string;
  description: string;
  shortDescription?: string | null;
  price: number;
  promotionalPrice?: number | null;
  mainImageUrl?: string | null;
  isActive: boolean;
  isFeatured: boolean;
  displayOrder: number;
  stockQuantity?: number | null;
  images: Array<{ imageUrl: string; displayOrder: number; isMain: boolean }>;
}
