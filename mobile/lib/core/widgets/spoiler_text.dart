import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Comment text that, when [isSpoiler], stays blurred behind a
/// "Spoiler içeriyor" label until tapped.
class SpoilerText extends StatefulWidget {
  const SpoilerText({
    required this.text,
    required this.isSpoiler,
    this.style,
    super.key,
  });

  final String text;
  final bool isSpoiler;
  final TextStyle? style;

  @override
  State<SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<SpoilerText> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final text = Text(widget.text, style: widget.style ?? AppTextStyles.bodyMd);
    if (!widget.isSpoiler || _revealed) return text;
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: text,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Spoiler içeriyor · göster',
                  style: AppTextStyles.labelSm.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
