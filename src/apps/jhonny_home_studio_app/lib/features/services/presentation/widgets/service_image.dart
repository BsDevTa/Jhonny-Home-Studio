import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_url_resolver.dart';

class ServiceImage extends StatelessWidget {
  const ServiceImage({
    super.key,
    required this.imageUrl,
    required this.label,
    this.icon = Icons.spa_rounded,
    this.aspectRatio = 16 / 10,
    this.borderRadius = 18,
    this.showLabel = true,
  });

  final String? imageUrl;
  final String label;
  final IconData icon;
  final double aspectRatio;
  final double borderRadius;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveMediaUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surfaceElevated),
          child: resolvedImageUrl.isEmpty
              ? _ServiceImagePlaceholder(
                  icon: icon,
                  label: label,
                  showLabel: showLabel,
                )
              : Image.network(
                  resolvedImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      'Erro ao carregar imagem do serviço: $resolvedImageUrl | $error',
                    );
                    return _ServiceImagePlaceholder(
                      icon: icon,
                      label: label,
                      showLabel: showLabel,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ServiceImagePlaceholder extends StatelessWidget {
  const _ServiceImagePlaceholder({
    required this.icon,
    required this.label,
    required this.showLabel,
  });

  final IconData icon;
  final String label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.18),
            AppColors.surfaceElevated,
            AppColors.copper.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold, size: 32),
              if (showLabel && label.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
