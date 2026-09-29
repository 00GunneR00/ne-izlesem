import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/feed_item_model.dart';
import '../../../data/models/friend_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/suggestion_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/feed_service.dart';
import '../../../data/services/friends_service.dart';
import '../../../data/services/groups_service.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/likes_service.dart';
import '../../../data/services/suggestions_service.dart';
import '../../../data/services/titles_service.dart';
import '../../../data/services/user_service.dart';
import '../../lists/controllers/lists_controller.dart';

class SocialController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final LibraryService _libraryService = LibraryService();
  final FriendsService _friendsService = FriendsService();
  final FeedService _feedService = FeedService();
  final UserService _userService = UserService();
  final LikesService _likesService = LikesService();
  final GroupsService _groupsService = GroupsService();
  final SuggestionsService _suggestionsService = SuggestionsService();
  final SessionService _session = Get.find();

  final Rxn<UserModel> me = Rxn<UserModel>();
  final RxList<FeedItemModel> feed = <FeedItemModel>[].obs;
  final RxList<TitleModel> trending = <TitleModel>[].obs;
  final RxList<FriendModel> friends = <FriendModel>[].obs;
  final RxList<FriendRequestModel> incomingRequests =
      <FriendRequestModel>[].obs;
  final RxList<UserSummaryModel> searchResults = <UserSummaryModel>[].obs;
  final RxList<GroupModel> groups = <GroupModel>[].obs;
  final RxList<SuggestionInboxItem> suggestionInbox =
      <SuggestionInboxItem>[].obs;
  final RxList<SuggestionNotification> suggestionNotifications =
      <SuggestionNotification>[].obs;
  final RxList<GroupMatchNotification> groupMatchNotifications =
      <GroupMatchNotification>[].obs;
  final RxMap<int, int> likeCounts = <int, int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSearching = false.obs;
  final RxInt selectedTab = 0.obs; // 0 = Arkadaş Akışı, 1 = Genel Trend, 2 = Listem
  final RxBool showingGroups = false.obs; // Arkadaşların/Gruplarım toggle

  void toggleConnectionsView() => showingGroups.toggle();

  int? get _userId => _session.userId.value;

  int get unseenNotificationCount =>
      incomingRequests.where((r) => !r.seen).length +
      suggestionNotifications.where((n) => !n.seen).length +
      groupMatchNotifications.where((n) => !n.seen).length;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Just the current user (e.g. after editing genre preferences).
  Future<void> refreshMe() async {
    final userId = _userId;
    if (userId == null) return;
    me.value = await _userService.getById(userId);
  }

  Future<void> reload() async {
    final userId = _userId;
    isLoading.value = true;
    try {
      me.value = userId != null ? await _userService.getById(userId) : null;
      final results = await Future.wait([
        userId != null
            ? _feedService.getFeed(userId)
            : Future.value(<FeedItemModel>[]),
        _titlesService.getTrending(MediaType.movie),
        userId != null
            ? _friendsService.getFriends(userId)
            : Future.value(<FriendModel>[]),
        userId != null
            ? _friendsService.getIncomingRequests(userId)
            : Future.value(<FriendRequestModel>[]),
        userId != null
            ? _groupsService.getForUser(userId)
            : Future.value(<GroupModel>[]),
        userId != null
            ? _suggestionsService.getInbox(userId)
            : Future.value(<SuggestionInboxItem>[]),
        userId != null
            ? _suggestionsService.getNotifications(userId)
            : Future.value(<SuggestionNotification>[]),
        userId != null
            ? _groupsService.getMatchNotifications(userId)
            : Future.value(<GroupMatchNotification>[]),
      ]);
      feed.value = results[0] as List<FeedItemModel>;
      trending.value = results[1] as List<TitleModel>;
      friends.value = results[2] as List<FriendModel>;
      incomingRequests.value = results[3] as List<FriendRequestModel>;
      groups.value = results[4] as List<GroupModel>;
      suggestionInbox.value = results[5] as List<SuggestionInboxItem>;
      suggestionNotifications.value =
          results[6] as List<SuggestionNotification>;
      groupMatchNotifications.value =
          results[7] as List<GroupMatchNotification>;
      likeCounts.value = trending.isEmpty
          ? {}
          : await _likesService.getCounts(
              trending.map((t) => t.tmdbId).toList(),
              MediaType.movie,
            );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGroup(String name, List<int> memberUserIds) async {
    final userId = _userId;
    final trimmed = name.trim();
    if (userId == null || trimmed.isEmpty) return;
    try {
      final group = await _groupsService.create(
        ownerId: userId,
        name: trimmed,
        memberUserIds: memberUserIds,
      );
      groups.add(group);
      Get.snackbar('Oluşturuldu', '"$trimmed" grubu oluşturuldu.');
    } catch (_) {
      Get.snackbar('Olmadı', 'Grup oluşturulamadı, tekrar dene.');
    }
  }

  Future<void> acceptSuggestion(SuggestionInboxItem item) async {
    final userId = _userId;
    if (userId == null) return;
    final matched = await _suggestionsService.accept(
      item.recipientRowId,
      userId,
    );
    suggestionInbox.removeWhere((s) => s.recipientRowId == item.recipientRowId);
    if (matched) {
      Get.snackbar(
        'Eşleşme! 🎉',
        '"${item.groupName}" grubunda herkes ${item.title.name} izlemek istiyor.',
      );
      reload(); // the new match shows up in notifications right away
    } else if (item.groupName != null) {
      Get.snackbar(
        'Onaylandı',
        '${item.title.name} için onayın "${item.groupName}" grubunun '
            'önerilerine eklendi.',
      );
    } else {
      Get.snackbar(
        'Eklendi',
        '${item.title.name} İzleyeceğim listesine eklendi.',
      );
    }
  }

  Future<void> passSuggestion(SuggestionInboxItem item) async {
    final userId = _userId;
    if (userId == null) return;
    await _suggestionsService.pass(item.recipientRowId, userId);
    suggestionInbox.removeWhere((s) => s.recipientRowId == item.recipientRowId);
  }

  /// "Tümünü okundu işaretle" — clears the bell badge. Pending friend
  /// requests stay in the list (they still need accept/decline), they just
  /// stop counting as unread.
  Future<void> markAllNotificationsSeen() async {
    final userId = _userId;
    if (userId == null || unseenNotificationCount == 0) return;
    try {
      await Future.wait([
        if (incomingRequests.any((r) => !r.seen))
          _friendsService.markRequestsSeen(userId),
        if (suggestionNotifications.any((n) => !n.seen))
          _suggestionsService.markNotificationsSeen(userId),
        if (groupMatchNotifications.any((n) => !n.seen))
          _groupsService.markMatchesSeen(userId),
      ]);
    } catch (_) {
      Get.snackbar('Olmadı', 'Bildirimler güncellenemedi, tekrar dene.');
      return;
    }
    incomingRequests.value = [
      for (final r in incomingRequests) r.markedSeen(),
    ];
    suggestionNotifications.value = [
      for (final n in suggestionNotifications)
        SuggestionNotification(
          recipientRowId: n.recipientRowId,
          recipientDisplayName: n.recipientDisplayName,
          title: n.title,
          status: n.status,
          respondedAt: n.respondedAt,
          seen: true,
        ),
    ];
    groupMatchNotifications.value = [
      for (final n in groupMatchNotifications) n.markedSeen(),
    ];
  }

  Future<void> sendSuggestion({
    required TitleModel title,
    String? note,
    List<int>? recipientUserIds,
    int? groupId,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _suggestionsService.send(
        senderId: userId,
        tmdbId: title.tmdbId,
        mediaType: title.mediaType,
        note: note,
        recipientUserIds: recipientUserIds,
        groupId: groupId,
      );
      Get.snackbar('Gönderildi', '${title.name} önerildi.');
    } catch (_) {
      Get.snackbar('Olmadı', 'Öneri gönderilemedi, tekrar dene.');
    }
  }

  void selectTab(int index) {
    selectedTab.value = index;
    // Listem shows collections; refresh so friends' new lists show up.
    if (index == 2) Get.find<ListsController>().reload();
  }

  int likeCountFor(int tmdbId) => likeCounts[tmdbId] ?? 0;

  /// Called right after a like toggle so the visible count updates instantly
  /// instead of waiting for a full reload.
  void adjustLikeCount(int tmdbId, int delta) {
    likeCounts[tmdbId] = (likeCounts[tmdbId] ?? 0) + delta;
  }

  Future<void> search(String query) async {
    final userId = _userId;
    final trimmed = query.trim();
    if (userId == null || trimmed.isEmpty) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      searchResults.value = await _userService.search(trimmed, userId);
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> sendRequestToUsername(String username) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _friendsService.sendRequestByUsername(userId, username);
      Get.snackbar(
        'İstek gönderildi',
        '@$username kullanıcısına arkadaşlık isteği gönderildi.',
      );
      searchResults.clear();
    } catch (_) {
      Get.snackbar('Olmadı', 'İstek gönderilemedi, tekrar dene.');
    }
  }

  Future<void> sendRequestByCode(String code) async {
    final userId = _userId;
    final trimmed = code.trim().toUpperCase();
    if (userId == null || trimmed.isEmpty) return;
    try {
      await _friendsService.sendRequestByFriendCode(userId, trimmed);
      Get.snackbar('İstek gönderildi', 'Arkadaşlık isteği gönderildi.');
    } catch (_) {
      Get.snackbar('Olmadı', 'Bu kodla bir kullanıcı bulunamadı.');
    }
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    final userId = _userId;
    if (userId == null) return;
    await _friendsService.accept(request.friendshipId, userId);
    await reload();
  }

  Future<void> declineRequest(FriendRequestModel request) async {
    final userId = _userId;
    if (userId == null) return;
    await _friendsService.decline(request.friendshipId, userId);
    incomingRequests.removeWhere((r) => r.friendshipId == request.friendshipId);
  }

  Future<void> addToList(TitleModel title) async {
    final userId = _userId;
    if (userId == null) return;
    await _libraryService.add(
      userId: userId,
      tmdbId: title.tmdbId,
      mediaType: title.mediaType,
      status: LibraryStatus.toWatch,
    );
    Get.snackbar('Eklendi', '${title.name} İzleyeceğim listesine eklendi.');
  }
}
