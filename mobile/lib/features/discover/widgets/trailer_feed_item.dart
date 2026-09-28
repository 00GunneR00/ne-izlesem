import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../../core/likes/likes_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/titles_service.dart';
import '../views/trailer_player_view.dart';

class TrailerFeedItem extends StatefulWidget {
  final TitleModel title;
  final String? Function(int genreId) genreName;

  const TrailerFeedItem({
    super.key,
    required this.title,
    required this.genreName,
  });

  @override
  State<TrailerFeedItem> createState() => _TrailerFeedItemState();
}

class _TrailerFeedItemState extends State<TrailerFeedItem> {
  final _titlesService = TitlesService();
  final _libraryService = LibraryService();
  final _session = Get.find<SessionService>();
  final _likes = Get.find<LikesController>();
  String? _trailerKey;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  Future<void> _loadTrailer() async {
    try {
      final trailers = await _titlesService.getTrailers(
        widget.title.mediaType,
        widget.title.tmdbId,
      );
      if (!mounted) return;
      if (trailers.isEmpty) {
        setState(() => _loadFailed = true);
        return;
      }
      setState(() => _trailerKey = trailers.first.key);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  void _playTrailer() {
    final key = _trailerKey;
    if (key == null) return;
    Get.to(() => TrailerPlayerView(videoId: key, title: widget.title.name));
  }

  void _addToList() {
    final userId = _session.userId.value;
    if (userId == null) return;
    _libraryService.add(
      userId: userId,
      tmdbId: widget.title.tmdbId,
      mediaType: widget.title.mediaType,
      status: LibraryStatus.toWatch,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İzleyeceğim listesine eklendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final year = title.releaseDate != null && title.releaseDate!.length >= 4
        ? title.releaseDate!.substring(0, 4)
        : null;
    final genreLabels = title.genreIds
        .map(widget.genreName)
        .whereType<String>()
        .take(2)
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (title.posterUrl != null || title.backdropUrl != null) ...[
          // Darkened cover-fill so there's never empty space around the
          // frame, with the actual poster drawn uncropped on top. No blur
          // filter here — a per-frame Gaussian blur (even downscaled) was
          // causing scroll jank and, combined with the upscaling transform,
          // GPU-driver crashes on device. A plain darkened cover is nearly
          // free to paint and still reads as an intentional backdrop.
          RepaintBoundary(
            child: CachedNetworkImage(
              imageUrl: title.posterUrl ?? title.backdropUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 360,
              color: AppColors.background.withValues(alpha: 0.75),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Center(
            child: CachedNetworkImage(
              imageUrl: title.posterUrl ?? title.backdropUrl!,
              fit: BoxFit.contain,
              memCacheWidth: 720,
            ),
          ),
        ] else
          Container(color: AppColors.surfaceContainer),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.2),
                AppColors.background.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: _trailerKey != null ? _playTrailer : null,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.85),
                border: Border.all(color: Colors.white24),
              ),
              child: _trailerKey == null && !_loadFailed
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _loadFailed ? Icons.videocam_off : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final label in genreLabels)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _tag(label),
                    ),
                  if (year != null) _tag(year),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(title.name, style: AppTextStyles.headlineLgMobile),
              const SizedBox(height: 4),
              Text(
                title.overview ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addToList,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Listeye Ekle'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Get.toNamed(AppRoutes.detail, arguments: title),
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('Detay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.md,
          bottom: 150,
          child: Obx(() {
            final liked = _likes.isLiked(title.tmdbId, title.mediaType);
            return InkWell(
              onTap: () => _likes.toggle(title),
              child: Column(
                children: [
                  Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? AppColors.primaryContainer : Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Beğen',
                    style: AppTextStyles.labelSm.copyWith(fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: AppColors.outline),
    ),
    child: Text(label, style: AppTextStyles.labelSm),
  );
}
