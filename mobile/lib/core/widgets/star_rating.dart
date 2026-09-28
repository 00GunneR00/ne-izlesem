import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Read-only 5-star row (friend feed).
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({required this.rating, this.size = 16, super.key});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i <= rating ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
    ],
  );
}

/// Tappable 5-star row. Tapping the current rating again clears it.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final int? rating;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '$i yıldız',
          onPressed: enabled ? () => onChanged(rating == i ? null : i) : null,
          icon: AnimatedScale(
            scale: (rating ?? 0) >= i ? 1.15 : 1,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              (rating ?? 0) >= i
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 30,
              color: (rating ?? 0) >= i
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
    ],
  );
}
