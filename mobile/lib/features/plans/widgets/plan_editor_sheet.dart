import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/plan_time.dart';
import '../../../data/models/title_model.dart';
import '../../social/controllers/social_controller.dart';
import '../controllers/plans_controller.dart';

enum _Who { solo, group, friends }

/// "Planla": pick when, and with whom — alone, a group (every member is
/// invited) or chosen friends. [groupId] preselects a group (film night
/// from the group page).
Future<void> showPlanEditor(TitleModel title, {int? groupId}) {
  return Get.bottomSheet(
    _PlanEditorSheet(title: title, initialGroupId: groupId),
    backgroundColor: AppColors.surfaceContainer,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
  );
}

class _PlanEditorSheet extends StatefulWidget {
  const _PlanEditorSheet({required this.title, this.initialGroupId});

  final TitleModel title;
  final int? initialGroupId;

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  final SocialController social = Get.find<SocialController>();
  final PlansController plans = Get.find<PlansController>();
  final _note = TextEditingController();

  late _Who _who = widget.initialGroupId != null ? _Who.group : _Who.solo;
  late int? _groupId = widget.initialGroupId;
  final Set<int> _friendIds = {};
  late DateTime _when = _defaultTime();
  bool _saving = false;

  /// Tonight 21:00, or tomorrow 21:00 if that's already past.
  static DateTime _defaultTime() {
    final now = DateTime.now();
    final tonight = DateTime(now.year, now.month, now.day, 21);
    return tonight.isAfter(now)
        ? tonight
        : tonight.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      _when.isAfter(DateTime.now()) &&
      switch (_who) {
        _Who.solo => true,
        _Who.group => _groupId != null,
        _Who.friends => _friendIds.isNotEmpty,
      };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
        () => _when = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _when.hour,
          _when.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (picked != null) {
      setState(
        () => _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final plan = await plans.create(
      title: widget.title,
      scheduledAt: _when,
      groupId: _who == _Who.group ? _groupId : null,
      friendIds: _who == _Who.friends ? _friendIds.toList() : null,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (plan != null) {
      Get.back();
      Get.snackbar(
        'Planlandı 📅',
        plan.isSolo
            ? '${plan.title.name} · ${formatPlanTime(plan.scheduledAt)}'
            : '${plan.title.name} · ${formatPlanTime(plan.scheduledAt)} — davetler gönderildi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Planla', style: AppTextStyles.headlineMd),
              Text(
                widget.title.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(formatPlanTime(_when).split(' ').first),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        '${_when.hour.toString().padLeft(2, '0')}:${_when.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              if (!_when.isAfter(DateTime.now()))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Geçmiş bir zaman seçtin.',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text('Kiminle?', style: AppTextStyles.labelSm),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<_Who>(
                segments: const [
                  ButtonSegment(
                    value: _Who.solo,
                    label: Text('Tek başıma'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: _Who.group,
                    label: Text('Grup'),
                    icon: Icon(Icons.group_outlined),
                  ),
                  ButtonSegment(
                    value: _Who.friends,
                    label: Text('Arkadaş'),
                    icon: Icon(Icons.people_outline),
                  ),
                ],
                selected: {_who},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _who = s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_who == _Who.group) _groupPicker(),
              if (_who == _Who.friends) _friendPicker(),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _note,
                maxLength: 200,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText:
                      'Not (isteğe bağlı) — ör. "Patlamış mısır bende 🍿"',
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
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _canSave ? _save : null,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.event_available),
                  label: Text(
                    _who == _Who.solo ? 'Planla' : 'Planla ve davet et',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupPicker() {
    final groups = social.groups;
    if (groups.isEmpty) {
      return _hint('Henüz bir grubun yok.');
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final g in groups)
          ChoiceChip(
            label: Text('${g.name} · ${g.members.length}'),
            selected: _groupId == g.id,
            onSelected: (_) => setState(() => _groupId = g.id),
          ),
      ],
    );
  }

  Widget _friendPicker() {
    final friends = social.friends;
    if (friends.isEmpty) {
      return _hint('Henüz arkadaşın yok.');
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final f in friends)
          FilterChip(
            label: Text(f.displayName),
            selected: _friendIds.contains(f.userId),
            onSelected: (on) => setState(
              () => on ? _friendIds.add(f.userId) : _friendIds.remove(f.userId),
            ),
          ),
      ],
    );
  }

  Widget _hint(String text) => Text(
    text,
    style: AppTextStyles.bodyMd.copyWith(
      fontSize: 13,
      color: AppColors.onSurfaceVariant,
    ),
  );
}
