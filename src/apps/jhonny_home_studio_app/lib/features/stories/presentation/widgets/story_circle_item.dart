import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_resolver.dart';

class StoryCircleItem extends StatelessWidget {
  const StoryCircleItem({
    super.key,
    required this.title,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveMediaUrl(imageUrl);
    debugPrint('Story circle resolvedUrl: $resolvedImageUrl');
    final hasImage = resolvedImageUrl.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(1.3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold,
                    AppColors.copper,
                    AppColors.goldDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          resolvedImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const _StoryPlaceholder();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Erro ao carregar imagem do Story: $resolvedImageUrl | $error',
                            );
                            return const _StoryPlaceholder();
                          },
                        )
                      : const _StoryPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPlaceholder extends StatelessWidget {
  const _StoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.goldDark,
            AppColors.copper,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 18,
        color: AppColors.champagne,
      ),
    );
  }
}

class StoryCircleSkeleton extends StatelessWidget {
  const StoryCircleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 46,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
