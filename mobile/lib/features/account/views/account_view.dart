import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../friends/views/friends_view.dart';
import '../../groups/views/groups_view.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/views/profile_view.dart';
import '../../social/controllers/social_controller.dart';
import '../widgets/delete_account_sheet.dart';

/// Personal account page — who you are (name/username) and quick access to
/// the counts that define your activity (watched/to-watch, friends, groups).
/// Reached from the hamburger drawer. Reuses SocialController and
/// ProfileController (both already alive via RootBinding) instead of
/// duplicating their state.
class AccountView extends GetView<SocialController> {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Aktivite',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              _statsGrid(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tercihler',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              _genrePreferencesTile(),
              const SizedBox(height: AppSpacing.xl),
              _dataAttribution(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Hesap',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              _deleteAccountTile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Obx(() {
    final me = controller.me.value;
    final name = me?.displayName;
    final initial = (name != null && name.isNotEmpty)
        ? name[0].toUpperCase()
        : '?';
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHigh,
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(child: Text(initial, style: AppTextStyles.headlineLg)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name ?? 'Kullanıcı',
                style: AppTextStyles.headlineLgMobile.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              if (me != null)
                Text(
                  '@${me.username}',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  });

  Widget _statsGrid() {
    final profile = Get.find<ProfileController>();
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.1,
        children: [
          _statCard(
            icon: Icons.check_circle_outline,
            label: 'İzlenen',
            value: profile.watchedCount,
            onTap: () {
              profile.changeMainTab(0);
              Get.to(() => const ProfileView());
            },
          ),
          _statCard(
            icon: Icons.bookmark_outline,
            label: 'İzleyeceğim',
            value: profile.toWatchCount,
            onTap: () {
              profile.changeMainTab(1);
              Get.to(() => const ProfileView());
            },
          ),
          _statCard(
            icon: Icons.people_outline,
            label: 'Arkadaş',
            value: controller.friends.length,
            onTap: () => Get.to(() => const FriendsView()),
          ),
          _statCard(
            icon: Icons.group_outlined,
            label: 'Grup',
            value: controller.groups.length,
            onTap: () => Get.to(() => const GroupsView()),
          ),
        ],
      ),
    );
  }

  /// Re-opens the onboarding genre picker in edit mode; Swipe picks the new
  /// genres up immediately.
  Widget _genrePreferencesTile() => InkWell(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    onTap: () async {
      await Get.toNamed(AppRoutes.onboarding, arguments: {'edit': true});
      controller.refreshMe(); // so the genre count below updates
    },
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.theater_comedy_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tür Tercihlerim', style: AppTextStyles.bodyMd),
                Obx(() {
                  final count =
                      controller.me.value?.preferredGenreIds.length ?? 0;
                  return Text(
                    count == 0
                        ? 'Henüz seçilmedi — Swipe önerilerini kişiselleştir'
                        : '$count tür seçili · Swipe bunlara göre öneriyor',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  );
                }),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
    ),
  );

  /// Google Play requires in-app account deletion.
  Widget _deleteAccountTile() => InkWell(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    onTap: DeleteAccountSheet.show,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.delete_forever_outlined, color: AppColors.primaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hesabımı Sil', style: AppTextStyles.bodyMd),
                Text(
                  'Hesabın ve tüm verilerin kalıcı olarak silinir',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
        ],
      ),
    ),
  );

  /// Required by TMDB's API terms: their logo plus the "not endorsed" notice.
  Widget _dataAttribution() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Veri Kaynağı',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SvgPicture.asset(
          'assets/attribution/tmdb_logo.svg',
          height: 14,
          semanticsLabel: 'The Movie Database (TMDB)',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Film ve dizi bilgileri, afişler ve fragmanlar TMDB API\'si '
          'kullanılarak sağlanmaktadır. Bu uygulama TMDB tarafından '
          'onaylanmamış veya sertifikalandırılmamıştır.',
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 10,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$value',
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
