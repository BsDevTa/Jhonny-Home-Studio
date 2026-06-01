import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../data/story_model.dart';

class StoryViewerScreen extends StatelessWidget {
  const StoryViewerScreen({super.key, required this.story});

  final StoryModel story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _StoryBackdrop(story: story),
                const _StoryOverlay(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: _StoryProgress()),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          height: 1.12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (story.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          story.subtitle,
                          style: const TextStyle(
                            color: AppColors.champagne,
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (story.hasLinkedService) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            onPressed: () => _openLinkedService(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              story.serviceName.trim().isEmpty
                                  ? 'Conhecer serviço'
                                  : 'Conhecer ${story.serviceName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLinkedService(BuildContext context) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('${AppRoutes.services}/${story.serviceId}');
  }
}

class _StoryBackdrop extends StatelessWidget {
  const _StoryBackdrop({required this.story});

  final StoryModel story;

  @override
  Widget build(BuildContext context) {
    if (!story.hasImage) {
      return const _StoryVisualPlaceholder();
    }

    return Image.network(
      story.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _StoryVisualPlaceholder();
      },
    );
  }
}

class _StoryVisualPlaceholder extends StatelessWidget {
  const _StoryVisualPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.goldDark,
            AppColors.copper,
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 54,
          color: AppColors.champagne,
        ),
      ),
    );
  }
}

class _StoryOverlay extends StatelessWidget {
  const _StoryOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x66000000), Color(0x11000000), Color(0xCC000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.textPrimary.withValues(alpha: 0.85),
      ),
    );
  }
}
