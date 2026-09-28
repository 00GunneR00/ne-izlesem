import 'package:flutter/material.dart';

/// Wraps a list tile so tapping an action (accept/decline/pass/etc.) plays a
/// shrink+fade exit animation before the underlying action actually runs and
/// removes the item from its list — instead of the row just vanishing the
/// instant the list mutates.
class DismissibleAction extends StatefulWidget {
  const DismissibleAction({required this.builder, super.key});

  /// Builds the tile content. Call the given `dismiss` function (instead of
  /// running your action directly) to play the exit animation first, then
  /// run [action] once it finishes.
  final Widget Function(
    BuildContext context,
    void Function(VoidCallback action) dismiss,
  )
  builder;

  @override
  State<DismissibleAction> createState() => _DismissibleActionState();
}

class _DismissibleActionState extends State<DismissibleAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<double> _shrink = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );
  bool _dismissed = false;

  void _dismiss(VoidCallback action) {
    if (_dismissed) return;
    _dismissed = true;
    _controller.forward().whenComplete(action);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1 - _shrink.value,
          child: Opacity(opacity: 1 - _shrink.value, child: child),
        ),
      ),
      child: widget.builder(context, _dismiss),
    );
  }
}
