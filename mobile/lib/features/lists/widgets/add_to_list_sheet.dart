import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/title_model.dart';
import '../controllers/lists_controller.dart';
import 'list_editor_dialog.dart';

/// "Listeye Ekle" from a title's detail page: tick/untick the user's lists,
/// or create a new one (the title is added to it right away).
Future<void> showAddToListSheet(TitleModel title) {
  return Get.bottomSheet(
    _AddToListSheet(title: title),
    backgroundColor: AppColors.surfaceContainer,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  );
}

class _AddToListSheet extends StatefulWidget {
  const _AddToListSheet({required this.title});

  final TitleModel title;

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  final ListsController lists = Get.find<ListsController>();
  Set<int>? _containing;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    if (lists.myLists.isEmpty) lists.reload();
    lists.listsContaining(widget.title).then((ids) {
      if (mounted) setState(() => _containing = ids);
    });
  }

  Future<void> _toggle(int listId) async {
    final contains = _containing ?? {};
    setState(() => _busy.add(listId));
    final wasIn = contains.contains(listId);
    final ok = wasIn
        ? await lists.removeTitle(listId, widget.title)
        : await lists.addTitle(listId, widget.title);
    if (!mounted) return;
    setState(() {
      _busy.remove(listId);
      if (ok) wasIn ? contains.remove(listId) : contains.add(listId);
    });
    // A removal changes the card's count/collage; the add path already
    // synced it from the server's response.
    if (ok && wasIn) lists.reload();
  }

  Future<void> _createAndAdd() async {
    final result = await showListEditor();
    if (result == null) return;
    final list = await lists.create(
      result.name,
      description: result.description,
      isShared: result.isShared,
    );
    if (list == null) return;
    await _toggle(list.id);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Listeye Ekle', style: AppTextStyles.headlineMd),
            Text(
              widget.title.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Obx(() {
                // Read the observables unconditionally: Obx must see at least
                // one, and `_containing` (plain State) isn't one.
                final loading = lists.isLoading.value;
                lists.myLists.length;
                final containing = _containing;
                if (containing == null || loading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (lists.myLists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'Henüz bir listen yok. İlkini oluştur!',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final list in lists.myLists)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: containing.contains(list.id),
                        onChanged: _busy.contains(list.id)
                            ? null
                            : (_) => _toggle(list.id),
                        activeColor: AppColors.primaryContainer,
                        title: Text(list.name, style: AppTextStyles.bodyMd),
                        subtitle: Text(
                          '${list.itemCount} yapım · '
                          '${list.isShared ? 'Paylaşılan' : 'Özel'}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createAndAdd,
                icon: const Icon(Icons.add),
                label: const Text('Yeni liste oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
