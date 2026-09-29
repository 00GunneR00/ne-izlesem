import '../../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/suggestion_model.dart';

class SuggestionsService {
  final _dio = ApiClient.instance.dio;

  Future<void> send({
    required int senderId,
    required int tmdbId,
    required MediaType mediaType,
    String? note,
    List<int>? recipientUserIds,
    int? groupId,
  }) =>
      _dio.post('/suggestions', data: {
        'senderId': senderId,
        'tmdbId': tmdbId,
        'mediaType': mediaType.apiValue,
        if (note != null && note.isNotEmpty) 'note': note,
        if (recipientUserIds != null) 'recipientUserIds': recipientUserIds,
        if (groupId != null) 'groupId': groupId,
      });

  Future<List<SuggestionInboxItem>> getInbox(int userId) async {
    final response = await _dio.get('/suggestions/inbox', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => SuggestionInboxItem.fromJson(e)).toList();
  }

  /// True when this accept made the whole group agree — a new group match.
  Future<bool> accept(int recipientRowId, int userId) async {
    final response = await _dio.post(
      '/suggestions/$recipientRowId/accept',
      queryParameters: {'userId': userId},
    );
    final data = response.data;
    return data is Map && data['matched'] == true;
  }

  Future<void> pass(int recipientRowId, int userId) =>
      _dio.post('/suggestions/$recipientRowId/pass', queryParameters: {'userId': userId});

  Future<List<SuggestionNotification>> getNotifications(int userId) async {
    final response = await _dio.get('/suggestions/notifications', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => SuggestionNotification.fromJson(e)).toList();
  }

  Future<void> markNotificationsSeen(int userId) =>
      _dio.post('/suggestions/notifications/mark-seen', queryParameters: {'userId': userId});

  /// "Temizle": hides already-read responses; unread ones stay.
  Future<void> clearReadNotifications(int userId) =>
      _dio.post('/suggestions/notifications/clear', queryParameters: {'userId': userId});
}
