import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Frosted-glass surface used for top bars, bottom nav and floating overlays,
/// matching the "Cinema Modern" glassmorphism component language.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final Border? border;
  final BorderRadius? borderRadius;
  final Color tint;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.border,
    this.borderRadius,
    this.tint = AppColors.surface,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        // BackdropFilter re-samples whatever scrolls underneath it every
        // frame (it can't be raster-cached like a one-off image blur), and
        // this container sits over actively scrolling content on several
        // screens — keep the sigma modest to bound that per-frame cost.
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: tint.withValues(alpha: opacity),
            border: border,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
