import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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

class _StoryBackdrop extends StatefulWidget {
  const _StoryBackdrop({required this.story});

  final StoryModel story;

  @override
  State<_StoryBackdrop> createState() => _StoryBackdropState();
}

class _StoryBackdropState extends State<_StoryBackdrop> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo && widget.story.hasMedia) {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.story.mediaUrl))
            ..setLooping(true)
            ..initialize().then((_) {
              if (!mounted) return;
              _controller?.play();
              setState(() {});
            });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        return const _StoryVisualPlaceholder();
      }
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }

    final imageUrl = widget.story.visualUrl.trim();
    if (imageUrl.isEmpty) {
      return const _StoryVisualPlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          'Erro ao carregar story ${widget.story.id} em $imageUrl: $error',
        );
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
