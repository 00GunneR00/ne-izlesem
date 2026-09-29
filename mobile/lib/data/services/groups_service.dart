import '../../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/group_model.dart';
import '../models/suggestion_model.dart';
import '../models/title_model.dart';
import 'swipe_service.dart' show SwipeDeck;

class GroupsService {
  final _dio = ApiClient.instance.dio;

  Future<GroupModel> create({required int ownerId, required String name, required List<int> memberUserIds}) async {
    final response = await _dio.post('/groups', data: {
      'ownerId': ownerId,
      'name': name,
      'memberUserIds': memberUserIds,
    });
    return GroupModel.fromJson(response.data);
  }

  Future<List<GroupModel>> getForUser(int userId) async {
    final response = await _dio.get('/groups', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => GroupModel.fromJson(e)).toList();
  }

  Future<void> delete(int groupId, int userId) =>
      _dio.delete('/groups/$groupId', queryParameters: {'userId': userId});

  /// "Grubun Önerileri": one entry per suggested title.
  Future<List<GroupSuggestion>> getSuggestions(int groupId, int userId) async {
    final response = await _dio.get('/groups/$groupId/suggestions', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => GroupSuggestion.fromJson(e)).toList();
  }

  /// Shared "Birlikte Seç" cards; titles other members liked come first.
  Future<SwipeDeck> getDeck({
    required int groupId,
    required int userId,
    required MediaType mediaType,
    required int page,
  }) async {
    final response = await _dio.get('/groups/$groupId/deck', queryParameters: {
      'userId': userId,
      'mediaType': mediaType.apiValue,
      'page': page,
    });
    return SwipeDeck.fromJson(response.data);
  }

  Future<GroupSwipeResult> swipe({
    required int groupId,
    required int userId,
    required TitleModel title,
    required SwipeDirection direction,
  }) async {
    final response = await _dio.post('/groups/$groupId/swipes', data: {
      'userId': userId,
      'tmdbId': title.tmdbId,
      'mediaType': title.mediaType.apiValue,
      'direction': direction.apiValue,
    });
    return GroupSwipeResult.fromJson(response.data);
  }

  Future<List<GroupMatch>> getMatches(int groupId, int userId) async {
    final response = await _dio.get('/groups/$groupId/matches', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => GroupMatch.fromJson(e)).toList();
  }

  Future<List<GroupMatchNotification>> getMatchNotifications(int userId) async {
    final response = await _dio.get('/groups/matches/notifications', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => GroupMatchNotification.fromJson(e)).toList();
  }

  Future<void> markMatchesSeen(int userId) =>
      _dio.post('/groups/matches/mark-seen', queryParameters: {'userId': userId});
}
