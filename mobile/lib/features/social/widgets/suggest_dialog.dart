import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/title_model.dart';
import '../controllers/social_controller.dart';

/// Opens the "Bunu izleyelim mi?" recipient picker for [title]. Reuses the
/// already-loaded friends/groups lists on [SocialController].
void showSuggestSheet(BuildContext context, TitleModel title) {
  final controller = Get.find<SocialController>();
  if (controller.friends.isEmpty && controller.groups.isEmpty) {
    Get.snackbar('Kimse yok', 'Önerebilmek için önce bir arkadaş eklemen ya da grup oluşturman lazım.');
    return;
  }

  final selectedFriendIds = <int>{}.obs;
  final selectedGroupId = RxnInt();
  final noteController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceContainer,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('"${title.name}" filmini öner', style: AppTextStyles.headlineMd.copyWith(fontSize: 18)),
              const SizedBox(height: AppSpacing.md),
              if (controller.groups.isNotEmpty) ...[
                Text('Grup Seç', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xs),
                Obx(() => Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final group in controller.groups)
                          ChoiceChip(
                            label: Text(group.name),
                            selected: selectedGroupId.value == group.id,
                            onSelected: (selected) {
                              selectedGroupId.value = selected ? group.id : null;
                              if (selected) selectedFriendIds.clear();
                            },
                          ),
                      ],
                    )),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.outline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text('VEYA', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider(color: AppColors.outline)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text('Arkadaş Seç', style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              Obx(() => Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final friend in controller.friends)
                        FilterChip(
                          label: Text(friend.displayName),
                          selected: selectedFriendIds.contains(friend.userId),
                          onSelected: (selected) {
                            if (selected) {
                              selectedFriendIds.add(friend.userId);
                              selectedGroupId.value = null;
                            } else {
                              selectedFriendIds.remove(friend.userId);
                            }
                          },
                        ),
                    ],
                  )),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: noteController,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Bir not ekle (isteğe bağlı)',
                  hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: Obx(() => FilledButton.icon(
                      onPressed: (selectedFriendIds.isEmpty && selectedGroupId.value == null)
                          ? null
                          : () {
                              controller.sendSuggestion(
                                title: title,
                                note: noteController.text,
                                recipientUserIds: selectedFriendIds.isEmpty ? null : selectedFriendIds.toList(),
                                groupId: selectedGroupId.value,
                              );
                              Navigator.of(sheetContext).pop();
                            },
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Öner'),
                    )),
              ),
            ],
          ),
        ),
      );
    },
  );
}
