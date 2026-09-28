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

  /// Tab index → library status: 0 = İzlediklerim, 1 = İzleyeceklerim,
  /// 2 = İzliyorum (shows in progress). Movies and shows are mixed in one
  /// backend-paginated stream per tab; the Film/Dizi/Tümü chip then just
  /// filters whatever's been loaded so far.
  static const tabStatuses = [
    LibraryStatus.watched,
    LibraryStatus.toWatch,
    LibraryStatus.watching,
  ];

  final List<RxList<LibraryEntryModel>> _entries = [
    for (final _ in tabStatuses) <LibraryEntryModel>[].obs,
  ];
  final List<int> _pages = [for (final _ in tabStatuses) 1];
  final List<bool> _hasMore = [for (final _ in tabStatuses) true];
  final List<RxBool> _isLoadingMore = [
    for (final _ in tabStatuses) false.obs,
  ];
  final List<RxInt> _totalCounts = [for (final _ in tabStatuses) 0.obs];

  final RxBool isLoading = true.obs;
  final RxnString displayName = RxnString();

  final RxInt mainTab = 0.obs;
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
  bool isLoadingMore(int tab) => _isLoadingMore[tab].value;

  int get watchedCount => _totalCounts[0].value;
  int get toWatchCount => _totalCounts[1].value;
  int get watchingCount => _totalCounts[2].value;

  int? get _userId => _session.userId.value;

  Future<void> refreshAll() async {
    final userId = _userId;
    if (userId == null) return;
    isLoading.value = true;
    for (var tab = 0; tab < tabStatuses.length; tab++) {
      _pages[tab] = 1;
      _hasMore[tab] = true;
    }
    try {
      final results = await Future.wait([
        for (final status in tabStatuses)
          _libraryService.getForUser(
            userId,
            status: status,
            page: 1,
            pageSize: _pageSize,
          ),
        for (final status in tabStatuses)
          _libraryService.getCount(userId, status: status),
      ]);
      for (var tab = 0; tab < tabStatuses.length; tab++) {
        final page = results[tab] as List<LibraryEntryModel>;
        _entries[tab].value = page;
        _hasMore[tab] = page.length >= _pageSize;
        _totalCounts[tab].value = results[tabStatuses.length + tab] as int;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by the grid when the user scrolls near the bottom of a tab.
  Future<void> loadMore(int tab) async {
    final userId = _userId;
    final loadingFlag = _isLoadingMore[tab];
    if (userId == null || !_hasMore[tab] || loadingFlag.value) return;
    loadingFlag.value = true;
    try {
      final nextPage = _pages[tab] + 1;
      final page = await _libraryService.getForUser(
        userId,
        status: tabStatuses[tab],
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

  int _tabOf(LibraryEntryModel entry) =>
      _entries.indexWhere((list) => list.any((e) => e.id == entry.id));

  void _decrement(int tab) =>
      _totalCounts[tab].value = (_totalCounts[tab].value - 1).clamp(0, 1 << 31);

  Future<void> markWatched(LibraryEntryModel entry) async {
    final updated = await _libraryService.updateStatus(
      entry.id,
      LibraryStatus.watched,
    );
    // Optimistic local move instead of a full refetch — with pagination a
    // wholesale refreshAll() would reset scroll position on every tap.
    final from = _tabOf(entry);
    if (from >= 0) {
      _entries[from].removeWhere((e) => e.id == entry.id);
      _decrement(from);
    }
    watched.insert(0, updated);
    _totalCounts[0].value += 1;
  }

  Future<void> remove(LibraryEntryModel entry) async {
    await _libraryService.remove(entry.id);
    final from = _tabOf(entry);
    if (from >= 0) {
      _entries[from].removeWhere((e) => e.id == entry.id);
      _decrement(from);
    }
  }
}
