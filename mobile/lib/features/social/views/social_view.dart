import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/likes/likes_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/friend_model.dart';
import '../../../data/models/title_model.dart';
import '../../account/widgets/app_drawer.dart';
import '../../groups/views/group_detail_view.dart';
import '../controllers/social_controller.dart';
import '../widgets/animated_like_icon.dart';
import '../widgets/notification_bell.dart';
import '../widgets/suggest_dialog.dart';

Color _avatarColor(String seed) {
  const palette = [
    Color(0xFFE07A5F),
    Color(0xFF3D5A80),
    Color(0xFF81B29A),
    Color(0xFFF2CC8F),
    Color(0xFFB56576),
  ];
  return palette[seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length];
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().toUtc().difference(dateTime.toUtc());
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
}

class SocialView extends GetView<SocialController> {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _topBar()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _connectionsSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _segmentedTabs(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (controller.selectedTab.value == 0) {
                  if (controller.feed.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Arkadaşlarından henüz bir hareket yok. Bir film beğen ya da yorum yaz, arkadaşların da paylaşınca burada görünsün.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: controller.feed.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) =>
                          _FeedCard(item: controller.feed[index]),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: controller.trending.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) =>
                        _TrendingCard(title: controller.trending[index]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => GlassContainer(
    border: const Border(bottom: BorderSide(color: AppColors.outline)),
    child: SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.sm),
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              'NE İZLESEM?',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: AppColors.primaryContainer,
                fontSize: 18,
              ),
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    ),
  );

  Widget _connectionsSection() => Obx(() {
    final hasFriends = controller.friends.isNotEmpty;
    final hasGroups = controller.groups.isNotEmpty;
    if (!hasFriends && !hasGroups) return const SizedBox.shrink();

    final showingGroups = controller.showingGroups.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                showingGroups ? 'Gruplarım' : 'Arkadaşların',
                key: ValueKey(showingGroups),
                style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.full),
              onTap: controller.toggleConnectionsView,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedRotation(
                  turns: showingGroups ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.sync_alt,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 76,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.12, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: showingGroups
                ? _groupsRailContent(key: const ValueKey('groups'))
                : _friendsRailContent(key: const ValueKey('friends')),
          ),
        ),
      ],
    );
  });

  Widget _friendsRailContent({Key? key}) {
    if (controller.friends.isEmpty) {
      return Align(
        key: key,
        alignment: Alignment.centerLeft,
        child: Text(
          'Henüz arkadaşın yok. Yukarıdan kullanıcı adı veya kodla ekleyebilirsin.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      key: key,
      scrollDirection: Axis.horizontal,
      itemCount: controller.friends.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) {
        final FriendModel friend = controller.friends[index];
        return SizedBox(
          width: 60,
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _avatarColor(friend.username),
                child: Text(
                  friend.displayName.isNotEmpty
                      ? friend.displayName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.headlineMd.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                friend.displayName,
                style: AppTextStyles.labelSm,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _groupsRailContent({Key? key}) {
    if (controller.groups.isEmpty) {
      return Align(
        key: key,
        alignment: Alignment.centerLeft,
        child: Text(
          'Henüz grubun yok. Hamburger menüden "Gruplarım" ile oluşturabilirsin.',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      key: key,
      scrollDirection: Axis.horizontal,
      itemCount: controller.groups.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) {
        final group = controller.groups[index];
        return GestureDetector(
          onTap: () => Get.to(() => GroupDetailView(group: group)),
          child: SizedBox(
            width: 60,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _avatarColor(group.name),
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  group.name,
                  style: AppTextStyles.labelSm,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _segmentedTabs() => Obx(
    () => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton('Arkadaş Akışı', 0)),
          Expanded(child: _tabButton('Genel Trend', 1)),
        ],
      ),
    ),
  );

  Widget _tabButton(String label, int index) {
    final selected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.selectTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItemModel item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    final title = item.title;
    final actionLabel = item.isComment ? 'bir yorum yaptı' : 'bir film beğendi';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _avatarColor(item.userDisplayName),
                  child: Text(
                    item.userDisplayName.isNotEmpty
                        ? item.userDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.userDisplayName} $actionLabel',
                        style: AppTextStyles.labelSm,
                      ),
                      Text(
                        _timeAgo(item.createdAt),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  item.isComment ? Icons.chat_bubble : Icons.favorite,
                  size: 18,
                  color: item.isComment
                      ? AppColors.tertiary
                      : AppColors.primaryContainer,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: title.posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: title.posterUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: AppColors.surfaceContainerLow),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.name,
                        style: AppTextStyles.headlineMd.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            title.voteAverage.toStringAsFixed(1),
                            style: AppTextStyles.labelSm,
                          ),
                        ],
                      ),
                      if (item.isComment && item.text != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '"${item.text}"',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => controller.addToList(title),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Listeye Ekle'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final TitleModel title;
  const _TrendingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    final likes = Get.find<LikesController>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 90,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: title.posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: title.posterUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(color: AppColors.surfaceContainerLow),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.name,
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        title.voteAverage.toStringAsFixed(1),
                        style: AppTextStyles.labelSm,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Obx(() {
                        final liked = likes.isLiked(
                          title.tmdbId,
                          title.mediaType,
                        );
                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () {
                            controller.adjustLikeCount(
                              title.tmdbId,
                              liked ? -1 : 1,
                            );
                            likes.toggle(title);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                AnimatedLikeIcon(
                                  liked: liked,
                                  likedColor: AppColors.primaryContainer,
                                  unlikedColor: AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Obx(
                                  () => Text(
                                    '${controller.likeCountFor(title.tmdbId)}',
                                    style: AppTextStyles.labelSm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        onPressed: () => showSuggestSheet(context, title),
                        icon: const Icon(
                          Icons.send_outlined,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                        tooltip: 'Öner',
                      ),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => controller.addToList(title),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ekle'),
                        ),
                      ),
                    ],
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
