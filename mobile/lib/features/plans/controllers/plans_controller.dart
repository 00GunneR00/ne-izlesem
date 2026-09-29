import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/plans_service.dart';

/// The user's watch plans, shared by Takip, the notifications page (plan
/// invites) and the "Planla" sheet.
class PlansController extends GetxController {
  final PlansService _service = PlansService();
  final SessionService _session = Get.find();

  final RxList<PlanModel> plans = <PlanModel>[].obs;
  final RxBool isLoading = true.obs;

  /// Plan ids with a request in flight (disables their buttons).
  final RxSet<int> busy = <int>{}.obs;

  int? get userId => _session.userId.value;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final id = userId;
    if (id == null) return;
    isLoading.value = plans.isEmpty;
    try {
      plans.value = await _service.getForUser(id);
    } catch (_) {
      // Keep whatever was shown; Takip offers pull-to-refresh.
    } finally {
      isLoading.value = false;
    }
  }

  bool isCreator(PlanModel p) => p.creatorId == userId;

  /// Not started yet and not declined — soonest first.
  List<PlanModel> get upcoming => plans
      .where((p) => !p.hasStarted && p.myResponse != PlanResponse.notGoing)
      .toList();

  PlanModel? get nextPlan => upcoming.isEmpty ? null : upcoming.first;

  /// Started plans the user was in on but hasn't answered "Nasıldı?" for.
  List<PlanModel> get needsOutcome => plans
      .where(
        (p) =>
            p.hasStarted &&
            p.myOutcome == null &&
            (p.myResponse == PlanResponse.going ||
                p.myResponse == PlanResponse.maybe),
      )
      .toList()
      .reversed
      .toList();

  /// Invitations still waiting for Katılıyorum / Belki / Gelemem.
  List<PlanModel> get pendingInvites => plans
      .where((p) => !p.hasStarted && p.myResponse == PlanResponse.pending)
      .toList();

  Future<PlanModel?> create({
    required TitleModel title,
    required DateTime scheduledAt,
    int? groupId,
    List<int>? friendIds,
    String? note,
  }) async {
    final id = userId;
    if (id == null) return null;
    try {
      final plan = await _service.create(
        userId: id,
        title: title,
        scheduledAt: scheduledAt,
        groupId: groupId,
        friendIds: friendIds,
        note: note,
      );
      plans
        ..add(plan)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return plan;
    } catch (_) {
      Get.snackbar('Olmadı', 'Plan oluşturulamadı, tekrar dene.');
      return null;
    }
  }

  Future<void> respond(PlanModel plan, PlanResponse response) =>
      _update(plan, () => _service.respond(plan.id, userId!, response));

  Future<void> setOutcome(PlanModel plan, PlanOutcome outcome) async {
    await _update(plan, () => _service.setOutcome(plan.id, userId!, outcome));
    if (outcome == PlanOutcome.watched) {
      Get.snackbar('İzlendi ✓', '${plan.title.name} kütüphanene eklendi.');
    }
  }

  Future<void> cancel(PlanModel plan) async {
    final id = userId;
    if (id == null || !busy.add(plan.id)) return;
    try {
      await _service.cancel(plan.id, id);
      plans.removeWhere((p) => p.id == plan.id);
    } catch (_) {
      Get.snackbar('Olmadı', 'Plan iptal edilemedi, tekrar dene.');
    } finally {
      busy.remove(plan.id);
    }
  }

  Future<void> _update(
    PlanModel plan,
    Future<PlanModel> Function() call,
  ) async {
    if (userId == null || !busy.add(plan.id)) return;
    try {
      final updated = await call();
      final index = plans.indexWhere((p) => p.id == plan.id);
      if (index >= 0) plans[index] = updated;
    } catch (_) {
      Get.snackbar('Olmadı', 'Kaydedilemedi, tekrar dene.');
    } finally {
      busy.remove(plan.id);
    }
  }
}
