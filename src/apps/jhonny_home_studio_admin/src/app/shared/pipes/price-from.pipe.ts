import { Pipe, PipeTransform } from '@angular/core';

import { ServicePriceFormatter } from '../../core/utils/service-price-formatter';

@Pipe({
  name: 'priceFrom',
  standalone: true,
})
export class PriceFromPipe implements PipeTransform {
  transform(value: number | null | undefined): string {
    return ServicePriceFormatter.startingAt(value);
  }
}
