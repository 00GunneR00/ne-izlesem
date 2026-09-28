import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../friends/views/friends_view.dart';
import '../../groups/views/groups_view.dart';
import '../../profile/views/profile_view.dart';
import '../views/account_view.dart';

/// Left-side navigation drawer, opened via the hamburger icon on the main
/// tabs. Order: Kütüphanem, Arkadaşlarım, Gruplarım, Profil, then Çıkış Yap
/// pinned to the bottom.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                'Ne İzlesem?',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
            const Divider(color: AppColors.outline, height: 1),
            ListTile(
              leading: const Icon(
                Icons.video_library_outlined,
                color: AppColors.primary,
              ),
              title: Text('Kütüphanem', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const ProfileView());
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.people_outline,
                color: AppColors.primary,
              ),
              title: Text('Arkadaşlarım', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const FriendsView());
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.group_outlined,
                color: AppColors.primary,
              ),
              title: Text('Gruplarım', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const GroupsView());
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
              ),
              title: Text('Profil', style: AppTextStyles.bodyMd),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const AccountView());
              },
            ),
            const Spacer(),
            const Divider(color: AppColors.outline, height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.onSurfaceVariant,
              ),
              title: Text(
                'Çıkış Yap',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: AppColors.onSurface),
        ),
        content: Text(
          'Farklı bir hesapla giriş yapmak için çıkış yapılsın mı?',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
              await Get.find<SessionService>().logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.primaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
