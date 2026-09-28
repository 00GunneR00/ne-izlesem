import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  static const _genreTints = [
    Color(0xFF3A2522),
    Color(0xFF2A1F3A),
    Color(0xFF223A2E),
    Color(0xFF3A2A22),
    Color(0xFF22303A),
    Color(0xFF3A2233),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: controller.isEditing
          ? AppBar(title: const Text('Tür Tercihlerim'))
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Text('Ne İzlesem?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayLg.copyWith(color: AppColors.primaryContainer)),
                  const SizedBox(height: 8),
                  Text('Hangi türleri seversin?',
                      textAlign: TextAlign.center, style: AppTextStyles.headlineMd),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sana en uygun film ve dizileri bulmamız için en az 3 tür seç.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 100),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.genres.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final genre = controller.genres[index];
                      final selected = controller.selectedGenreIds.contains(genre.id);
                      return _GenreCard(
                        label: genre.name,
                        tint: _genreTints[index % _genreTints.length],
                        selected: selected,
                        onTap: () => controller.toggleGenre(genre.id),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassContainer(
        tint: AppColors.background,
        opacity: 0.8,
        border: const Border(top: BorderSide(color: AppColors.outline)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Obx(() => SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: controller.canContinue
                          ? [BoxShadow(color: AppColors.glowPrimary, blurRadius: 15, spreadRadius: 1)]
                          : null,
                    ),
                    child: FilledButton(
                      onPressed: controller.canContinue ? controller.completeOnboarding : null,
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(controller.isEditing ? 'Kaydet' : 'Devam Et'),
                    ),
                  ),
                )),
          ),
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String label;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  const _GenreCard({
    required this.label,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
              ),
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
