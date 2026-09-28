import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/views/notifications_view.dart';
import '../controllers/social_controller.dart';

/// Bell icon with an unseen-count badge, shown on every main tab's top bar.
/// Tapping it opens the notifications page (friend requests, suggestions,
/// suggestion responses). Reuses SocialController (already alive via
/// RootBinding) so the badge count stays in sync across tabs.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _bounce = TweenSequence([
    TweenSequenceItem(
      weight: 35,
      tween: Tween(
        begin: 1.0,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
    TweenSequenceItem(
      weight: 30,
      tween: Tween(
        begin: 1.3,
        end: 0.9,
      ).chain(CurveTween(curve: Curves.easeInOut)),
    ),
    TweenSequenceItem(
      weight: 35,
      tween: Tween(
        begin: 0.9,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
    ),
  ]).animate(_controller);
  int? _lastCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: () => Get.to(() => const NotificationsView()),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Obx(() {
          final count = controller.unseenNotificationCount;
          // Skip the very first build (no prior count to compare against) —
          // only pop the badge when a *new* notification actually arrives.
          if (_lastCount != null && count > _lastCount!) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _controller.forward(from: 0);
            });
          }
          _lastCount = count;
          return ScaleTransition(
            scale: _bounce,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, color: AppColors.primary),
                if (count > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
