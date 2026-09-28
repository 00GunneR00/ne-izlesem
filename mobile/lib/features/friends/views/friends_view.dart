import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../social/controllers/social_controller.dart';

/// Friends list + adding new friends (by username search or friend code).
/// Reached from the hamburger drawer. Reuses SocialController (already alive
/// via RootBinding) instead of duplicating friend-search state.
class FriendsView extends GetView<SocialController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Arkadaşlarım')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _friendsList(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Yeni Arkadaş Ekle',
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              _friendCodeSection(context, codeController),
              const SizedBox(height: AppSpacing.md),
              _searchBar(searchController),
              Obx(() {
                if (controller.searchResults.isEmpty)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _searchResultsList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _friendsList() => Obx(() {
    if (controller.friends.isEmpty) {
      return Text(
        'Henüz arkadaşın yok. Aşağıdan kullanıcı adıyla ara ya da arkadaş kodunu paylaş.',
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (final friend in controller.friends)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.displayName, style: AppTextStyles.bodyMd),
                      Text(
                        '@${friend.username}',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  });

  Widget _friendCodeSection(
    BuildContext context,
    TextEditingController codeController,
  ) => Obx(() {
    final code = controller.me.value?.friendCode;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Arkadaş Kodun: ',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                code ?? '—',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (code != null)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kod kopyalandı')),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: codeController,
                  style: AppTextStyles.bodyMd,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Kod ile ekle (örn. AB12CD3)',
                    hintStyle: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () {
                  controller.sendRequestByCode(codeController.text);
                  codeController.clear();
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  });

  Widget _searchBar(TextEditingController searchController) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: searchController,
            style: AppTextStyles.bodyMd,
            onSubmitted: controller.search,
            decoration: InputDecoration(
              hintText: 'Kullanıcı adıyla arkadaş bul...',
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.arrow_forward,
            color: AppColors.primary,
            size: 18,
          ),
          onPressed: () => controller.search(searchController.text),
        ),
      ],
    ),
  );

  Widget _searchResultsList() => Column(
    children: [
      for (final user in controller.searchResults)
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: AppTextStyles.bodyMd),
                    Text(
                      '@${user.username}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    controller.sendRequestToUsername(user.username),
                child: const Text('Ekle'),
              ),
            ],
          ),
        ),
    ],
  );
}
