import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/user_list_model.dart';
import '../controllers/lists_controller.dart';
import '../widgets/list_editor_dialog.dart';

/// One collection. Owners can rename/share, delete the list and remove
/// titles; friends see it read-only. Titles are added from a title's detail
/// page ("Listeye Ekle").
class ListDetailView extends StatefulWidget {
  const ListDetailView({required this.list, super.key});

  final UserListSummary list;

  @override
  State<ListDetailView> createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<ListDetailView> {
  final ListsController lists = Get.find<ListsController>();
  late UserListSummary _list = widget.list;
  List<TitleModel>? _items;
  bool _failed = false;

  bool get _isMine => _list.ownerId == lists.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await lists.load(_list.id);
      if (!mounted || detail == null) return;
      setState(() {
        _list = detail.list;
        _items = detail.items;
        _failed = false;
      });
      if (_isMine) lists.syncSummary(detail.list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _edit() async {
    final result = await showListEditor(initial: _list);
    if (result == null) return;
    final updated = await lists.updateList(
      _list,
      name: result.name,
      description: result.description,
      isShared: result.isShared,
    );
    if (updated != null && mounted) setState(() => _list = updated);
  }

  Future<void> _delete() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text('Listeyi sil', style: AppTextStyles.headlineMd),
        content: Text(
          '"${_list.name}" kalıcı olarak silinecek. Listedeki yapımlar '
          'kütüphanende kalır.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && await lists.deleteList(_list)) Get.back();
  }

  Future<void> _remove(TitleModel title) async {
    if (await lists.removeTitle(_list.id, title)) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(_list.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (_isMine)
            PopupMenuButton<String>(
              color: AppColors.surfaceContainerHigh,
              onSelected: (value) => value == 'edit' ? _edit() : _delete(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                PopupMenuItem(value: 'delete', child: Text('Listeyi sil')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              if (_failed)
                _message('Liste yüklenemedi. Aşağı çekip tekrar dene.')
              else if (items == null)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                _message(
                  _isMine
                      ? 'Liste boş. Bir film ya da dizinin detayından '
                            '"Listeye Ekle" ile ekleyebilirsin.'
                      : 'Bu liste henüz boş.',
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.52,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _itemCard(items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((_list.description ?? '').isNotEmpty) ...[
          Text(_list.description!, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Icon(
              _list.isShared ? Icons.people_outline : Icons.lock_outline,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              [
                if (!_isMine) _list.ownerDisplayName,
                _list.isShared ? 'Arkadaşlarla paylaşılan' : 'Özel',
                '${_list.itemCount} yapım',
              ].join(' · '),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _message(String text) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
    ),
  );

  Widget _itemCard(TitleModel title) => GestureDetector(
    onTap: () => Get.toNamed(AppRoutes.detail, arguments: title),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: title.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: title.posterUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.surfaceContainer),
              ),
            ),
            if (_isMine)
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _remove(title),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSm,
        ),
      ],
    ),
  );
}
