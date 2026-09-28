import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/user_service.dart';

enum ProfileMediaFilter { all, movie, show }

class ProfileController extends GetxController {
  final LibraryService _libraryService = LibraryService();
  final UserService _userService = UserService();
  final SessionService _session = Get.find();

  static const _pageSize = 24;

  // Index 0 = İzlediklerim (watched), 1 = İzleyeceklerim (toWatch) — movies
  // and shows are mixed in one backend-paginated stream per tab; the
  // Film/Dizi/Tümü chip then just filters whatever's been loaded so far.
  final List<RxList<LibraryEntryModel>> _entries = [
    <LibraryEntryModel>[].obs,
    <LibraryEntryModel>[].obs,
  ];
  final List<int> _pages = [1, 1];
  final List<bool> _hasMore = [true, true];
  final RxBool isLoadingMoreWatched = false.obs;
  final RxBool isLoadingMoreToWatch = false.obs;

  final RxInt watchedTotalCount = 0.obs;
  final RxInt toWatchTotalCount = 0.obs;

  final RxBool isLoading = true.obs;
  final RxnString displayName = RxnString();

  final RxInt mainTab = 0.obs; // 0 = İzlediklerim, 1 = İzleyeceklerim
  final Rx<ProfileMediaFilter> selectedFilter = ProfileMediaFilter.all.obs;

  RxList<LibraryEntryModel> get watched => _entries[0];
  RxList<LibraryEntryModel> get toWatch => _entries[1];

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    refreshAll();
  }

  Future<void> _loadUser() async {
    final userId = _userId;
    if (userId == null) return;
    final user = await _userService.getById(userId);
    displayName.value = user.displayName;
  }

  void changeMainTab(int index) => mainTab.value = index;
  void changeFilter(ProfileMediaFilter filter) => selectedFilter.value = filter;

  List<LibraryEntryModel> entriesFor(int tab) {
    final list = _entries[tab];
    switch (selectedFilter.value) {
      case ProfileMediaFilter.movie:
        return list.where((e) => e.title.mediaType == MediaType.movie).toList();
      case ProfileMediaFilter.show:
        return list.where((e) => e.title.mediaType == MediaType.show).toList();
      case ProfileMediaFilter.all:
        return list;
    }
  }

  /// Whether more pages exist for this tab — the grid uses this to decide
  /// whether to keep a loading footer around.
  bool hasMoreFor(int tab) => _hasMore[tab];

  int get watchedCount => watchedTotalCount.value;
  int get toWatchCount => toWatchTotalCount.value;

  int? get _userId => _session.userId.value;

  LibraryStatus _statusFor(int tab) =>
      tab == 0 ? LibraryStatus.watched : LibraryStatus.toWatch;

  Future<void> refreshAll() async {
    final userId = _userId;
    if (userId == null) return;
    isLoading.value = true;
    _pages[0] = 1;
    _pages[1] = 1;
    _hasMore[0] = true;
    _hasMore[1] = true;
    try {
      final results = await Future.wait([
        _libraryService.getForUser(
          userId,
          status: LibraryStatus.watched,
          page: 1,
          pageSize: _pageSize,
        ),
        _libraryService.getForUser(
          userId,
          status: LibraryStatus.toWatch,
          page: 1,
          pageSize: _pageSize,
        ),
        _libraryService.getCount(userId, status: LibraryStatus.watched),
        _libraryService.getCount(userId, status: LibraryStatus.toWatch),
      ]);
      watched.value = results[0] as List<LibraryEntryModel>;
      toWatch.value = results[1] as List<LibraryEntryModel>;
      _hasMore[0] = watched.length >= _pageSize;
      _hasMore[1] = toWatch.length >= _pageSize;
      watchedTotalCount.value = results[2] as int;
      toWatchTotalCount.value = results[3] as int;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by the grid when the user scrolls near the bottom of a tab.
  Future<void> loadMore(int tab) async {
    final userId = _userId;
    final loadingFlag = tab == 0 ? isLoadingMoreWatched : isLoadingMoreToWatch;
    if (userId == null || !_hasMore[tab] || loadingFlag.value) return;
    loadingFlag.value = true;
    try {
      final nextPage = _pages[tab] + 1;
      final page = await _libraryService.getForUser(
        userId,
        status: _statusFor(tab),
        page: nextPage,
        pageSize: _pageSize,
      );
      _entries[tab].addAll(page);
      _pages[tab] = nextPage;
      _hasMore[tab] = page.length >= _pageSize;
    } finally {
      loadingFlag.value = false;
    }
  }

  Future<void> markWatched(LibraryEntryModel entry) async {
    await _libraryService.updateStatus(entry.id, LibraryStatus.watched);
    // Optimistic local move instead of a full refetch — with pagination a
    // wholesale refreshAll() would reset scroll position on every tap.
    toWatch.removeWhere((e) => e.id == entry.id);
    watched.insert(
      0,
      LibraryEntryModel(
        id: entry.id,
        userId: entry.userId,
        title: entry.title,
        status: LibraryStatus.watched,
        addedAt: entry.addedAt,
      ),
    );
    toWatchTotalCount.value = (toWatchTotalCount.value - 1).clamp(0, 1 << 31);
    watchedTotalCount.value += 1;
  }

  Future<void> remove(LibraryEntryModel entry) async {
    await _libraryService.remove(entry.id);
    final wasWatched = watched.any((e) => e.id == entry.id);
    watched.removeWhere((e) => e.id == entry.id);
    toWatch.removeWhere((e) => e.id == entry.id);
    if (wasWatched) {
      watchedTotalCount.value = (watchedTotalCount.value - 1).clamp(0, 1 << 31);
    } else {
      toWatchTotalCount.value = (toWatchTotalCount.value - 1).clamp(0, 1 << 31);
    }
  }
}
