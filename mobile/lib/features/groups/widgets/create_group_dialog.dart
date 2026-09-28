import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../social/controllers/social_controller.dart';

void showCreateGroupDialog(BuildContext context) {
  final controller = Get.find<SocialController>();
  final nameController = TextEditingController();
  final selectedIds = <int>{}.obs;
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Grup Oluştur', style: TextStyle(color: AppColors.onSurface)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Grup adı (örn. Evimiz)',
                hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (controller.friends.isEmpty)
              Text('Grup üyesi eklemek için önce arkadaş ekle.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant))
            else
              Obx(() => Column(
                    children: [
                      for (final friend in controller.friends)
                        CheckboxListTile(
                          value: selectedIds.contains(friend.userId),
                          onChanged: (checked) {
                            if (checked ?? false) {
                              selectedIds.add(friend.userId);
                            } else {
                              selectedIds.remove(friend.userId);
                            }
                          },
                          title: Text(friend.displayName, style: AppTextStyles.bodyMd),
                          activeColor: AppColors.primaryContainer,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Vazgeç')),
        TextButton(
          onPressed: () {
            controller.createGroup(nameController.text, selectedIds.toList());
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Oluştur'),
        ),
      ],
    ),
  );
}
