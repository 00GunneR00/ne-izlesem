import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/user_list_model.dart';
import '../../../data/services/lists_service.dart';

/// "Listem": the user's own collections plus friends' shared ones. Shared
/// by the Sosyal tab, the list detail page and the "Listeye Ekle" sheet so
/// every change shows up everywhere without refetching.
class ListsController extends GetxController {
  final ListsService _service = ListsService();
  final SessionService _session = Get.find();

  final RxList<UserListSummary> myLists = <UserListSummary>[].obs;
  final RxList<UserListSummary> friendsLists = <UserListSummary>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  int? get userId => _session.userId.value;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final id = userId;
    if (id == null) return;
    isLoading.value = myLists.isEmpty && friendsLists.isEmpty;
    try {
      final results = await Future.wait([
        _service.getMine(id),
        _service.getFriends(id),
      ]);
      myLists.value = results[0];
      friendsLists.value = results[1];
      hasError.value = false;
    } catch (_) {
      hasError.value = myLists.isEmpty && friendsLists.isEmpty;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns the new list, or null (with a snackbar) on failure.
  Future<UserListSummary?> create(
    String name, {
    String? description,
    required bool isShared,
  }) async {
    final id = userId;
    if (id == null) return null;
    try {
      final list = await _service.create(
        userId: id,
        name: name,
        description: description,
        isShared: isShared,
      );
      myLists.insert(0, list);
      return list;
    } catch (_) {
      Get.snackbar('Olmadı', 'Liste oluşturulamadı, tekrar dene.');
      return null;
    }
  }

  Future<UserListSummary?> updateList(
    UserListSummary list, {
    required String name,
    String? description,
    required bool isShared,
  }) async {
    final id = userId;
    if (id == null) return null;
    try {
      final updated = await _service.update(
        list.id,
        userId: id,
        name: name,
        description: description,
        isShared: isShared,
      );
      _replace(updated);
      return updated;
    } catch (_) {
      Get.snackbar('Olmadı', 'Liste güncellenemedi, tekrar dene.');
      return null;
    }
  }

  Future<bool> deleteList(UserListSummary list) async {
    final id = userId;
    if (id == null) return false;
    try {
      await _service.delete(list.id, id);
      myLists.removeWhere((l) => l.id == list.id);
      return true;
    } catch (_) {
      Get.snackbar('Olmadı', 'Liste silinemedi, tekrar dene.');
      return false;
    }
  }

  Future<Set<int>> listsContaining(TitleModel title) async {
    final id = userId;
    if (id == null) return {};
    try {
      return await _service.getContaining(id, title);
    } catch (_) {
      return {};
    }
  }

  Future<bool> addTitle(int listId, TitleModel title) async {
    final id = userId;
    if (id == null) return false;
    try {
      _replace(await _service.addItem(listId, id, title), moveToTop: true);
      return true;
    } catch (_) {
      Get.snackbar('Olmadı', 'Listeye eklenemedi, tekrar dene.');
      return false;
    }
  }

  Future<bool> removeTitle(int listId, TitleModel title) async {
    final id = userId;
    if (id == null) return false;
    try {
      await _service.removeItem(listId, id, title);
      return true;
    } catch (_) {
      Get.snackbar('Olmadı', 'Listeden çıkarılamadı, tekrar dene.');
      return false;
    }
  }

  Future<UserListDetail?> load(int listId) async {
    final id = userId;
    if (id == null) return null;
    return _service.get(listId, id);
  }

  /// Keeps card data (count, collage) in sync after edits.
  void syncSummary(UserListSummary list) => _replace(list);

  void _replace(UserListSummary list, {bool moveToTop = false}) {
    final index = myLists.indexWhere((l) => l.id == list.id);
    if (index < 0) return;
    if (moveToTop) {
      myLists
        ..removeAt(index)
        ..insert(0, list);
    } else {
      myLists[index] = list;
    }
  }
}
