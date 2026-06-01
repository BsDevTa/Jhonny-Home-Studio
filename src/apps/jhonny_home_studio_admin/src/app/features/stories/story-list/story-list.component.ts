import { DatePipe } from '@angular/common';
import { Component, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { StudioStory } from '../../../core/models/story.model';
import { StoryService } from '../../../core/services/story.service';
import { ConfirmDialogComponent } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../shared/components/empty-state/empty-state.component';
import { LoadingComponent } from '../../../shared/components/loading/loading.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

@Component({
  selector: 'app-story-list',
  standalone: true,
  imports: [DatePipe, RouterLink, ConfirmDialogComponent, EmptyStateComponent, LoadingComponent, StatusBadgeComponent],
  templateUrl: './story-list.component.html',
  styleUrl: './story-list.component.scss'
})
export class StoryListComponent implements OnInit {
  readonly stories = signal<StudioStory[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly storyToDelete = signal<StudioStory | null>(null);

  constructor(private readonly storyService: StoryService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.error.set('');

    this.storyService.getAll().subscribe({
      next: (stories) => {
        this.stories.set(stories);
        this.loading.set(false);
      },
      error: (error: Error) => {
        this.error.set(error.message);
        this.loading.set(false);
      }
    });
  }

  toggle(story: StudioStory): void {
    this.error.set('');
    this.storyService.toggleActive(story.id).subscribe({
      next: () => this.load(),
      error: (error: Error) => this.error.set(error.message)
    });
  }

  confirmDelete(): void {
    const story = this.storyToDelete();
    if (!story) {
      return;
    }

    this.storyService.delete(story.id).subscribe({
      next: () => {
        this.storyToDelete.set(null);
        this.load();
      },
      error: (error: Error) => {
        this.storyToDelete.set(null);
        this.error.set(error.message);
      }
    });
  }
}
