import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { LoyaltyModel } from '../models/loyalty.model';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class LoyaltyService {
  constructor(private readonly api: ApiService) {}

  getForCustomer(customerId: string): Observable<LoyaltyModel> {
    return this.api.get<LoyaltyModel>(`/api/admin/customers/${customerId}/loyalty`);
  }
}
