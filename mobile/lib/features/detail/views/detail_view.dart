import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/likes/likes_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/person_model.dart';
import '../../search/views/person_filmography_view.dart';
import '../../social/widgets/animated_like_icon.dart';
import '../../social/widgets/suggest_dialog.dart';
import '../controllers/detail_controller.dart';

/// Placeholder model for a future TMDB watch-providers integration.
class WatchProvider {
  final String name;
  const WatchProvider({required this.name});
}

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final title = controller.title;
    final trailerKey = GlobalKey();
    final scrollController = ScrollController();
    final year = title.releaseDate != null && title.releaseDate!.length >= 4
        ? title.releaseDate!.substring(0, 4)
        : null;

    void scrollToTrailer() {
      final ctx = trailerKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: title.backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: title.backdropUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.surfaceContainer),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: InkWell(
                      onTap: scrollToTrailer,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.8,
                          ),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 4,
                  child: SafeArea(
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 4,
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => showSuggestSheet(context, title),
                          icon: const Icon(
                            Icons.send_outlined,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Bunu izleyelim mi? diye öner',
                        ),
                        Obx(() {
                          final liked = Get.find<LikesController>().isLiked(
                            title.tmdbId,
                            title.mediaType,
                          );
                          return IconButton(
                            onPressed: () =>
                                Get.find<LikesController>().toggle(title),
                            icon: AnimatedLikeIcon(
                              liked: liked,
                              likedColor: AppColors.primaryContainer,
                              unlikedColor: AppColors.primary,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'title-${title.tmdbId}-${title.mediaType.name}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: SizedBox(
                            width: 100,
                            height: 150,
                            child: title.posterUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: title.posterUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: AppColors.surfaceContainer),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Obx(
                          () => Column(
                            children: [
                              FilledButton.icon(
                                onPressed: () => controller.saveToLibrary(
                                  LibraryStatus.toWatch,
                                ),
                                icon: Icon(
                                  controller.savedStatus.value ==
                                          LibraryStatus.toWatch
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                ),
                                label: const Text('İzleyeceğim'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: () => controller.saveToLibrary(
                                  LibraryStatus.watched,
                                ),
                                icon: Icon(
                                  controller.savedStatus.value ==
                                          LibraryStatus.watched
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                ),
                                label: const Text('İzledim'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(
                    () => AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child:
                          controller.savedStatus.value == LibraryStatus.watched
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Puanın',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  StarRatingInput(
                                    rating: controller.rating.value,
                                    onChanged: controller.setRating,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() {
                    // Read genres unconditionally so GetX always has an
                    // observable to track here, even when title.genreIds is
                    // empty (older cached titles, or genre-less TMDB entries).
                    final loadedGenres = controller.genres;
                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final id in title.genreIds)
                          if (loadedGenres.any((g) => g.id == id))
                            _tag(controller.genreName(id)!),
                        if (year != null) _tag(year),
                        _tag(
                          '★ ${title.voteAverage.toStringAsFixed(1)}',
                          highlight: true,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title.name,
                    style: AppTextStyles.displayLg.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Özet', style: AppTextStyles.headlineMd),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title.overview ?? '', style: AppTextStyles.bodyLg),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Fragman',
                    key: trailerKey,
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.trailers.isEmpty) {
                      return Text(
                        'Fragman bulunamadı.',
                        style: AppTextStyles.bodyMd,
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: YoutubePlayer(
                        controller: YoutubePlayerController.fromVideoId(
                          videoId: controller.trailers.first.key,
                          autoPlay: false,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),
                  _CastSection(controller: controller),
                  const SizedBox(height: AppSpacing.lg),
                  _CommentsSection(controller: controller),
                  const SizedBox(height: AppSpacing.lg),
                  const _WhereToWatchSection(providers: null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, {bool highlight = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.3)
            : AppColors.outline,
      ),
    ),
    child: Text(
      label,
      style: AppTextStyles.labelSm.copyWith(
        color: highlight ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
    ),
  );
}

class _CommentsSection extends StatelessWidget {
  final DetailController controller;
  const _CommentsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yorumlar', style: AppTextStyles.headlineMd),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                style: AppTextStyles.bodyMd,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Bir yorum yaz...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Obx(
              () => IconButton.filled(
                onPressed: controller.isPostingComment.value
                    ? null
                    : () {
                        final text = textController.text;
                        textController.clear();
                        controller.postComment(text);
                      },
                icon: controller.isPostingComment.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          if (controller.comments.isEmpty) {
            return Text(
              'Henüz yorum yok. İlk yorumu sen yaz.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            );
          }
          return Column(
            children: [
              for (final comment in controller.comments)
                _CommentTile(comment: comment),
            ],
          );
        }),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.userDisplayName,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(comment.text, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

/// Cast list (3–8 members, per the backend's /cast endpoint) — tapping a
/// member opens their filmography, reusing the search feature's page.
class _CastSection extends StatelessWidget {
  final DetailController controller;
  const _CastSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cast = controller.cast;
      // Fewer than 3 credited cast members isn't worth a whole section.
      if (cast.length < 3) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oyuncular', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final member = cast[index];
                return GestureDetector(
                  onTap: () => Get.to(
                    () => PersonFilmographyView(
                      person: PersonModel(
                        tmdbId: member.personId,
                        name: member.name,
                        profileUrl: member.profileUrl,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.surfaceContainerLow,
                          backgroundImage: member.profileUrl != null
                              ? CachedNetworkImageProvider(member.profileUrl!)
                              : null,
                          child: member.profileUrl == null
                              ? Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.name,
                          style: AppTextStyles.labelSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (member.character != null)
                          Text(
                            member.character!,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

/// Renders TMDB watch-provider links once/if that's brought into scope;
/// hidden for now — real platform deep links are explicitly out of MVP scope.
class _WhereToWatchSection extends StatelessWidget {
  final List<WatchProvider>? providers;
  const _WhereToWatchSection({required this.providers});

  @override
  Widget build(BuildContext context) {
    if (providers == null || providers!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nerede İzlenir', style: AppTextStyles.headlineMd),
        const SizedBox(height: AppSpacing.sm),
        for (final provider in providers!)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(provider.name, style: AppTextStyles.bodyMd),
          ),
      ],
    );
  }
}
