import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs';

import {
  ProductCategoryModel,
  ProductModel,
  resolveUrl,
  UpsertProductCategoryRequest,
  UpsertProductRequest,
} from '../models/marketplace.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class MarketplaceService {
  constructor(private readonly api: ApiService) {}

  getCategories(): Observable<ProductCategoryModel[]> {
    return this.api.get<ProductCategoryModel[]>('/api/admin/marketplace/categories');
  }

  getCategoryById(id: string): Observable<ProductCategoryModel> {
    return this.api.get<ProductCategoryModel>(`/api/admin/marketplace/categories/${id}`);
  }

  createCategory(request: UpsertProductCategoryRequest): Observable<ProductCategoryModel> {
    return this.api.post<ProductCategoryModel>('/api/admin/marketplace/categories', request);
  }

  updateCategory(
    id: string,
    request: UpsertProductCategoryRequest,
  ): Observable<ProductCategoryModel> {
    return this.api.put<ProductCategoryModel>(`/api/admin/marketplace/categories/${id}`, request);
  }

  toggleCategoryActive(id: string): Observable<ProductCategoryModel> {
    return this.api.patch<ProductCategoryModel>(
      `/api/admin/marketplace/categories/${id}/toggle-active`,
    );
  }

  deleteCategory(id: string): Observable<unknown> {
    return this.api.delete(`/api/admin/marketplace/categories/${id}`);
  }

  getProducts(): Observable<ProductModel[]> {
    return this.api
      .get<ProductModel[]>('/api/admin/marketplace/products')
      .pipe(map((products) => products.map((product) => this.normalizeProduct(product))));
  }

  getProductById(id: string): Observable<ProductModel> {
    return this.api
      .get<ProductModel>(`/api/admin/marketplace/products/${id}`)
      .pipe(map((product) => this.normalizeProduct(product)));
  }

  createProduct(request: UpsertProductRequest): Observable<ProductModel> {
    return this.api
      .post<ProductModel>('/api/admin/marketplace/products', request)
      .pipe(map((product) => this.normalizeProduct(product)));
  }

  updateProduct(id: string, request: UpsertProductRequest): Observable<ProductModel> {
    return this.api
      .put<ProductModel>(`/api/admin/marketplace/products/${id}`, request)
      .pipe(map((product) => this.normalizeProduct(product)));
  }

  toggleProductActive(id: string): Observable<ProductModel> {
    return this.api.patch<ProductModel>(`/api/admin/marketplace/products/${id}/toggle-active`);
  }

  deleteProduct(id: string): Observable<unknown> {
    return this.api.delete(`/api/admin/marketplace/products/${id}`);
  }

  uploadProductImage(file: File): Observable<{ imageUrl: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api.postForm<{ imageUrl: string }>(
      '/api/admin/marketplace/products/upload-image',
      formData,
    );
  }

  private normalizeProduct(product: ProductModel): ProductModel {
    return {
      ...product,
      mainImageUrl: resolveUrl(product.mainImageUrl),
      images: product.images.map((image) => ({
        ...image,
        imageUrl: resolveUrl(image.imageUrl),
      })),
    };
  }
}
