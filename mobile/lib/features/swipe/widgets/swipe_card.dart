import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/title_model.dart';

class SwipeCard extends StatefulWidget {
  final TitleModel title;
  final String? Function(int genreId) genreName;
  final void Function(SwipeDirection direction) onSwiped;

  const SwipeCard({
    super.key,
    required this.title,
    required this.genreName,
    required this.onSwiped,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  static const _swipeThreshold = 110.0;
  bool _isExiting = false;

  late final AnimationController _controller = AnimationController(vsync: this);
  Animation<Offset>? _driftAnimation;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isExiting) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isExiting) return;
    if (_dragOffset.dx > _swipeThreshold) {
      _flyOff(SwipeDirection.like);
    } else if (_dragOffset.dx < -_swipeThreshold) {
      _flyOff(SwipeDirection.pass);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _driftAnimation =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        )..addListener(
          () => setState(() => _dragOffset = _driftAnimation!.value),
        );
    _controller
      ..duration = const Duration(milliseconds: 420)
      ..reset()
      ..forward();
  }

  void _flyOff(SwipeDirection direction) {
    setState(() => _isExiting = true);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final endX = direction == SwipeDirection.like
        ? screenWidth * 1.4
        : -screenWidth * 1.4;
    _driftAnimation =
        Tween<Offset>(
            begin: _dragOffset,
            end: Offset(endX, _dragOffset.dy),
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn))
          ..addListener(
            () => setState(() => _dragOffset = _driftAnimation!.value),
          );
    _controller
      ..duration = const Duration(milliseconds: 320)
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) widget.onSwiped(direction);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = _dragOffset.dx / 300;
    final likeOpacity = (_dragOffset.dx / _swipeThreshold)
        .clamp(0, 1)
        .toDouble();
    final passOpacity = (-_dragOffset.dx / _swipeThreshold)
        .clamp(0, 1)
        .toDouble();
    final year =
        widget.title.releaseDate != null &&
            widget.title.releaseDate!.length >= 4
        ? widget.title.releaseDate!.substring(0, 4)
        : null;
    final genreLabels = widget.title.genreIds
        .map(widget.genreName)
        .whereType<String>()
        .take(2)
        .toList();

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: widget.title.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.title.posterUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                Container(color: AppColors.surfaceContainer),
                          )
                        : Container(color: AppColors.surfaceContainer),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.lg),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final label in genreLabels)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.full,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: AppTextStyles.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.title.voteAverage.toStringAsFixed(1),
                            style: AppTextStyles.labelSm,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.title.name,
                        style: AppTextStyles.headlineLg.copyWith(fontSize: 24),
                      ),
                      if (year != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          year,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 24,
                left: 24,
                child: Opacity(
                  opacity: passOpacity,
                  child: _stampLabel('GEÇ', AppColors.secondary),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: Opacity(
                  opacity: likeOpacity,
                  child: _stampLabel('İZLEDİM', AppColors.primaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stampLabel(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: color, width: 3),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Text(
      text,
      style: AppTextStyles.headlineMd.copyWith(color: color, fontSize: 18),
    ),
  );
}
