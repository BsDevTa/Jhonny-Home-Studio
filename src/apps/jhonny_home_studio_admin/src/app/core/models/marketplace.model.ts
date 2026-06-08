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
