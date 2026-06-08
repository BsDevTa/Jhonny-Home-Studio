import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import {
  ProductCategoryModel,
  ProductModel,
  UpsertProductCategoryRequest,
  UpsertProductRequest
} from '../models/marketplace.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class MarketplaceService {
  constructor(private readonly api: ApiService) {}

  getCategories(): Observable<ProductCategoryModel[]> {
    return this.api.get<ProductCategoryModel[]>('/admin/marketplace/categories');
  }

  getCategoryById(id: string): Observable<ProductCategoryModel> {
    return this.api.get<ProductCategoryModel>(`/admin/marketplace/categories/${id}`);
  }

  createCategory(request: UpsertProductCategoryRequest): Observable<ProductCategoryModel> {
    return this.api.post<ProductCategoryModel>('/admin/marketplace/categories', request);
  }

  updateCategory(id: string, request: UpsertProductCategoryRequest): Observable<ProductCategoryModel> {
    return this.api.put<ProductCategoryModel>(`/admin/marketplace/categories/${id}`, request);
  }

  toggleCategoryActive(id: string): Observable<ProductCategoryModel> {
    return this.api.patch<ProductCategoryModel>(`/admin/marketplace/categories/${id}/toggle-active`);
  }

  deleteCategory(id: string): Observable<unknown> {
    return this.api.delete(`/admin/marketplace/categories/${id}`);
  }

  getProducts(): Observable<ProductModel[]> {
    return this.api.get<ProductModel[]>('/admin/marketplace/products');
  }

  getProductById(id: string): Observable<ProductModel> {
    return this.api.get<ProductModel>(`/admin/marketplace/products/${id}`);
  }

  createProduct(request: UpsertProductRequest): Observable<ProductModel> {
    return this.api.post<ProductModel>('/admin/marketplace/products', request);
  }

  updateProduct(id: string, request: UpsertProductRequest): Observable<ProductModel> {
    return this.api.put<ProductModel>(`/admin/marketplace/products/${id}`, request);
  }

  toggleProductActive(id: string): Observable<ProductModel> {
    return this.api.patch<ProductModel>(`/admin/marketplace/products/${id}/toggle-active`);
  }

  deleteProduct(id: string): Observable<unknown> {
    return this.api.delete(`/admin/marketplace/products/${id}`);
  }

  uploadProductImage(file: File): Observable<{ imageUrl: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api.postForm<{ imageUrl: string }>('/admin/marketplace/products/upload-image', formData);
  }
}
