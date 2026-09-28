import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/services/titles_service.dart';
import '../../discover/views/trailer_player_view.dart';
import '../controllers/social_controller.dart';
import 'dismissible_action.dart';

/// A single "Bunu izleyelim mi?" suggestion, with trailer preview and
/// accept/pass actions. Used on the notifications page's suggestion inbox.
class SuggestionCard extends StatefulWidget {
  final SuggestionInboxItem item;
  const SuggestionCard({required this.item, super.key});

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  final _titlesService = TitlesService();
  bool _loadingTrailer = false;

  Future<void> _watchTrailer() async {
    setState(() => _loadingTrailer = true);
    try {
      final title = widget.item.title;
      final trailers = await _titlesService.getTrailers(
        title.mediaType,
        title.tmdbId,
      );
      if (!mounted) return;
      if (trailers.isEmpty) {
        Get.snackbar('Fragman yok', 'Bu başlık için fragman bulunamadı.');
        return;
      }
      Get.to(
        () => TrailerPlayerView(videoId: trailers.first.key, title: title.name),
      );
    } finally {
      if (mounted) setState(() => _loadingTrailer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    final item = widget.item;
    return DismissibleAction(
      builder: (context, dismiss) =>
          _buildCard(context, controller, item, dismiss),
    );
  }

  Widget _buildCard(
    BuildContext context,
    SocialController controller,
    SuggestionInboxItem item,
    void Function(VoidCallback action) dismiss,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 70,
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: item.title.posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.title.posterUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.surfaceContainerLow),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.groupName != null
                            ? '${item.senderDisplayName} (${item.groupName})'
                            : item.senderDisplayName,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title.name,
                        style: AppTextStyles.headlineMd.copyWith(fontSize: 16),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '"${item.note}"',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _loadingTrailer ? null : _watchTrailer,
                icon: _loadingTrailer
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Fragmanı İzle'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        dismiss(() => controller.passSuggestion(item)),
                    child: const Text('Geç'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () =>
                        dismiss(() => controller.acceptSuggestion(item)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                    ),
                    child: Text(
                      item.groupName != null
                          ? 'Kabul Et'
                          : 'İzleyeceğim Listeme Ekle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
