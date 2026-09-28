import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../social/controllers/social_controller.dart';
import '../widgets/create_group_dialog.dart';
import 'group_detail_view.dart';

/// Full list of the user's groups + creating new ones. Reached from the
/// hamburger drawer. Reuses SocialController (already alive via RootBinding).
class GroupsView extends GetView<SocialController> {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruplarım'),
        actions: [
          TextButton.icon(
            onPressed: () => showCreateGroupDialog(context),
            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
            label: const Text('Yeni Grup'),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Henüz grubun yok. Örn. "Evimiz" grubunu oluşturup birlikte yaşadığın kişiyi ekleyebilirsin.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: controller.groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final group = controller.groups[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => Get.to(() => GroupDetailView(group: group)),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceVariant,
                            ),
                            child: const Icon(
                              Icons.group,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              group.name,
                              style: AppTextStyles.headlineMd.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final member in group.members)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                member.displayName,
                                style: AppTextStyles.labelSm,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
