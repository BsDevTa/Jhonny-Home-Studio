import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ServiceStoryItem extends StatelessWidget {
  const ServiceStoryItem({
    super.key,
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.icon,
  });

  final String title;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title.trim();
    final initials = _buildInitials(trimmedTitle);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7E6642),
                    Color(0xFFB89A62),
                    Color(0xFF4A3A23),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.7),
                    width: 0.6,
                  ),
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _PlaceholderContent(
                              icon: icon,
                              initials: initials,
                            );
                          },
                        )
                      : _PlaceholderContent(icon: icon, initials: initials),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trimmedTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  String _buildInitials(String value) {
    if (value.isEmpty) {
      return 'JH';
    }

    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return value.characters.take(2).toString().toUpperCase();
    }

    if (parts.length == 1) {
      final firstWord = parts.first;
      return firstWord.characters.take(2).toString().toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({required this.initials, this.icon});

  final String initials;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF17110B), Color(0xFF1E1A16), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: icon == null
            ? Text(
                initials,
                style: const TextStyle(
                  color: AppColors.goldSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(icon, size: 18, color: AppColors.goldSoft),
      ),
    );
  }
}

class ServiceStorySkeleton extends StatelessWidget {
  const ServiceStorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
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
