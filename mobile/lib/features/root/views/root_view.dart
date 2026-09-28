import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_container.dart';
import '../../discover/views/discover_view.dart';
import '../../search/views/search_view.dart';
import '../../social/views/social_view.dart';
import '../../swipe/views/swipe_view.dart';
import '../controllers/root_controller.dart';

class RootView extends GetView<RootController> {
  const RootView({super.key});

  static const _tabs = [
    (icon: Icons.swipe, label: 'Swipe'),
    (icon: Icons.explore, label: 'Keşfet'),
    (icon: Icons.search, label: 'Arama'),
    (icon: Icons.group, label: 'Sosyal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.tabIndex.value,
          children: const [
            SwipeView(),
            DiscoverView(),
            SearchView(),
            SocialView(),
          ],
        ),
        bottomNavigationBar: GlassContainer(
          border: const Border(top: BorderSide(color: AppColors.outline)),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _tabs[i].icon,
                        label: _tabs[i].label,
                        selected: controller.tabIndex.value == i,
                        onTap: () => controller.changeTab(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryContainer.withValues(alpha: 0.2)
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
