import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Layered dark-gradient backdrop standing in for the Stitch mockups'
/// hotlinked cinema-still photos (those Stitch preview URLs aren't stable
/// app assets, so this recreates the same moody depth without them).
class CinematicBackground extends StatelessWidget {
  final Widget child;

  const CinematicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Positioned(
          top: -120,
          right: -80,
          child: _glow(320, AppColors.primaryContainer.withValues(alpha: 0.25)),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _glow(300, AppColors.surfaceVariant.withValues(alpha: 0.4)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.4),
                AppColors.background,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}
