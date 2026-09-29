import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/enums.dart';
import '../../../data/services/titles_service.dart';
import 'cinematic_background.dart';

/// Sign-in backdrop: three tilted columns of trending posters drifting
/// endlessly (alternate directions and speeds), darkened toward the form.
/// Falls back to the glow gradient while posters load or if they can't.
class PosterWall extends StatefulWidget {
  const PosterWall({super.key});

  @override
  State<PosterWall> createState() => _PosterWallState();
}

class _PosterWallState extends State<PosterWall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  List<String> _posters = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = TitlesService();
      final results = await Future.wait([
        service.getTrending(MediaType.movie),
        service.getTrending(MediaType.show),
      ]);
      final urls = results
          .expand((l) => l)
          .map((t) => t.posterUrl)
          .whereType<String>()
          .toList();
      if (mounted && urls.length >= 9) setState(() => _posters = urls);
    } catch (_) {
      // Offline / backend down → the glow backdrop stays.
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CinematicBackground(child: SizedBox.shrink()),
        AnimatedOpacity(
          opacity: _posters.isEmpty ? 0 : 1,
          duration: const Duration(milliseconds: 900),
          child: _posters.isEmpty ? const SizedBox.shrink() : _wall(),
        ),
        // Dim the wall, fading to solid background where the form sits.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.35, 0.7],
              colors: [
                Color(0x99000000),
                Color(0xCC0A0A0A),
                AppColors.background,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _wall() => LayoutBuilder(
    builder: (context, constraints) {
      // Wider than the screen so the tilt never shows an edge.
      final columnWidth = constraints.maxWidth * 1.4 / 3;
      const gap = 10.0;
      final posterHeight = columnWidth * 1.5;
      return OverflowBox(
        maxWidth: constraints.maxWidth * 1.4,
        maxHeight: constraints.maxHeight * 1.4,
        child: Transform.rotate(
          angle: -0.18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < 3; c++)
                SizedBox(
                  width: columnWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: gap / 2),
                    child: _column(c, posterHeight, gap),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  /// One endlessly scrolling column: its posters repeated twice so the
  /// wrap-around is seamless; odd columns scroll the other way.
  Widget _column(int index, double posterHeight, double gap) {
    final posters = [
      for (var i = index; i < _posters.length; i += 3) _posters[i],
    ];
    final setHeight = posters.length * (posterHeight + gap);
    final speed = 1.0 + index * 0.35;
    return ClipRect(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, child) {
          final travel = (_drift.value * speed * setHeight) % setHeight;
          final dy = index.isOdd ? travel - setHeight : -travel;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        // Taller than the screen on purpose — laid out unbounded, clipped above.
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final url in [...posters, ...posters])
                Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      height: posterHeight,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
