import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_list_model.dart';

typedef ListEditorResult = ({String name, String? description, bool isShared});

/// Create (no [initial]) or edit a list: name, optional description, and
/// whether friends can see it. Resolves to null when cancelled.
Future<ListEditorResult?> showListEditor({UserListSummary? initial}) {
  return Get.dialog<ListEditorResult>(_ListEditorDialog(initial: initial));
}

class _ListEditorDialog extends StatefulWidget {
  const _ListEditorDialog({this.initial});

  final UserListSummary? initial;

  @override
  State<_ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<_ListEditorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late bool _isShared = widget.initial?.isShared ?? true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: Text(
        widget.initial == null ? 'Yeni Liste' : 'Listeyi Düzenle',
        style: AppTextStyles.headlineMd,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              _name,
              hint: 'Liste adı (ör. En iyi gerilimler 🔪)',
              maxLength: 60,
              autofocus: widget.initial == null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _description,
              hint: 'Açıklama (isteğe bağlı)',
              maxLength: 200,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isShared,
              onChanged: (value) => setState(() => _isShared = value),
              activeThumbColor: AppColors.primaryContainer,
              title: Text('Arkadaşlarımla paylaş', style: AppTextStyles.bodyMd),
              subtitle: Text(
                _isShared
                    ? 'Arkadaşların bu listeyi görebilir.'
                    : 'Sadece sen görebilirsin.',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Vazgeç')),
        FilledButton(
          onPressed: _canSave
              ? () => Get.back(
                  result: (
                    name: _name.text.trim(),
                    description: _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                    isShared: _isShared,
                  ),
                )
              : null,
          child: Text(widget.initial == null ? 'Oluştur' : 'Kaydet'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String hint,
    required int maxLength,
    int maxLines = 1,
    bool autofocus = false,
  }) => TextField(
    controller: controller,
    autofocus: autofocus,
    maxLength: maxLength,
    maxLines: maxLines,
    minLines: 1,
    onChanged: (_) => setState(() {}),
    style: AppTextStyles.bodyMd,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      counterText: '',
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
  );
}
