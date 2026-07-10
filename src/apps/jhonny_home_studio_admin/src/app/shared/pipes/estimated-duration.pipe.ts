import { Pipe, PipeTransform } from '@angular/core';

import { DurationFormatter } from '../../core/utils/duration-formatter';

@Pipe({
  name: 'estimatedDuration',
  standalone: true,
})
export class EstimatedDurationPipe implements PipeTransform {
  transform(minutes: number | null | undefined): string {
    return DurationFormatter.estimated(minutes);
  }
}
