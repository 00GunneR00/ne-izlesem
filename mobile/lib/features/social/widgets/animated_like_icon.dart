import 'package:flutter/material.dart';

/// A heart icon that "pops" (scale bounce) whenever [liked] flips to true —
/// the familiar like-button micro-interaction. Purely presentational; caller
/// still owns the tap handler and the liked state.
class AnimatedLikeIcon extends StatefulWidget {
  const AnimatedLikeIcon({
    required this.liked,
    required this.likedColor,
    required this.unlikedColor,
    this.size = 24,
    super.key,
  });

  final bool liked;
  final Color likedColor;
  final Color unlikedColor;
  final double size;

  @override
  State<AnimatedLikeIcon> createState() => _AnimatedLikeIconState();
}

class _AnimatedLikeIconState extends State<AnimatedLikeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      weight: 40,
      tween: Tween(
        begin: 1.0,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(
      weight: 60,
      tween: Tween(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant AnimatedLikeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.liked && !oldWidget.liked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.liked ? Icons.favorite : Icons.favorite_border,
        size: widget.size,
        color: widget.liked ? widget.likedColor : widget.unlikedColor,
      ),
    );
  }
}
