import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_list_model.dart';
import '../../lists/controllers/lists_controller.dart';
import '../../lists/views/list_detail_view.dart';
import '../../lists/widgets/list_card.dart';
import '../../lists/widgets/list_editor_dialog.dart';

/// Sosyal's "Listem" tab: "Listelerim" (own collections + create) and
/// "Arkadaşlarının Listeleri" (friends' shared ones), as one sliver inside
/// the Sosyal scroll. Call from inside an Obx — it reads the observables.
Widget listsSliver(ListsController lists) {
  final mine = lists.myLists.toList();
  final friends = lists.friendsLists.toList();

  if (lists.isLoading.value) {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
  if (lists.hasError.value) {
    return SliverToBoxAdapter(
      child: _hint('Listeler yüklenemedi. Aşağı çekip tekrar dene.'),
    );
  }

  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.xl,
    ),
    sliver: SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Listelerim',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: () => _create(lists),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Liste'),
              ),
            ],
          ),
        ),
        if (mine.isEmpty)
          SliverToBoxAdapter(
            child: _hint(
              'Kendi koleksiyonlarını oluştur: "En iyi gerilimler", '
              '"Sevgilimle izlenecekler"… Arkadaşlarınla paylaşabilirsin.',
            ),
          )
        else
          _grid(mine, showOwner: false),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Arkadaşlarının Listeleri',
              style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
            ),
          ),
        ),
        if (friends.isEmpty)
          SliverToBoxAdapter(
            child: _hint('Arkadaşlarının paylaştığı bir liste henüz yok.'),
          )
        else
          _grid(friends, showOwner: true),
      ],
    ),
  );
}

Future<void> _create(ListsController lists) async {
  final result = await showListEditor();
  if (result == null) return;
  final list = await lists.create(
    result.name,
    description: result.description,
    isShared: result.isShared,
  );
  if (list != null) Get.to(() => ListDetailView(list: list));
}

Widget _grid(List<UserListSummary> items, {required bool showOwner}) =>
    SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListCard(
          list: items[index],
          showOwner: showOwner,
          onTap: () => Get.to(() => ListDetailView(list: items[index])),
        ),
        childCount: items.length,
      ),
    );

Widget _hint(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  child: Text(
    text,
    style: AppTextStyles.bodyMd.copyWith(
      fontSize: 13,
      color: AppColors.onSurfaceVariant,
    ),
  ),
);
