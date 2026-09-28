import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';

/// App launch animation: the play-mark glows and scales in, then the
/// wordmark rises under it, before handing off to root/login. Pure Flutter
/// animations — no bundled video or external renderer.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _markScale = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );
  late final Animation<double> _markFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );
  late final Animation<Offset> _wordmarkSlide =
      Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
    // Hold well past the entrance animation's own duration (1200ms) so the
    // glow pulse gets a couple of full cycles on screen before we navigate —
    // the intro should fully land, not get cut off mid-animation.
    Future.delayed(const Duration(milliseconds: 3200), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final session = Get.find<SessionService>();
    Get.offNamed(session.hasUser ? AppRoutes.root : AppRoutes.login);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_entrance, _pulse]),
              builder: (context, child) {
                final glow = 0.5 + (_pulse.value * 0.5);
                return Opacity(
                  opacity: _markFade.value,
                  child: Transform.scale(
                    scale: _markScale.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.glowPrimary.withValues(
                              alpha: glow,
                            ),
                            blurRadius: 32 + (_pulse.value * 16),
                            spreadRadius: 2 + (_pulse.value * 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: _wordmarkFade,
              child: SlideTransition(
                position: _wordmarkSlide,
                child: Text(
                  'NE İZLESEM?',
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.primaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
