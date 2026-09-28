import '../../core/network/api_client.dart';
import '../models/title_model.dart';
import '../models/user_list_model.dart';

class ListsService {
  final _dio = ApiClient.instance.dio;

  Future<List<UserListSummary>> getMine(int userId) async {
    final response = await _dio.get('/lists/mine', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => UserListSummary.fromJson(e)).toList();
  }

  /// Lists the user's friends chose to share.
  Future<List<UserListSummary>> getFriends(int userId) async {
    final response = await _dio.get('/lists/friends', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => UserListSummary.fromJson(e)).toList();
  }

  Future<UserListDetail> get(int listId, int userId) async {
    final response = await _dio.get('/lists/$listId', queryParameters: {'userId': userId});
    return UserListDetail.fromJson(response.data);
  }

  /// Ids of the user's own lists that already contain this title.
  Future<Set<int>> getContaining(int userId, TitleModel title) async {
    final response = await _dio.get('/lists/containing', queryParameters: {
      'userId': userId,
      'tmdbId': title.tmdbId,
      'mediaType': title.mediaType.apiValue,
    });
    return (response.data as List).cast<int>().toSet();
  }

  Future<UserListSummary> create({
    required int userId,
    required String name,
    String? description,
    required bool isShared,
  }) async {
    final response = await _dio.post('/lists', data: {
      'userId': userId,
      'name': name,
      'description': description,
      'isShared': isShared,
    });
    return UserListSummary.fromJson(response.data);
  }

  Future<UserListSummary> update(
    int listId, {
    required int userId,
    required String name,
    String? description,
    required bool isShared,
  }) async {
    final response = await _dio.put('/lists/$listId', data: {
      'userId': userId,
      'name': name,
      'description': description,
      'isShared': isShared,
    });
    return UserListSummary.fromJson(response.data);
  }

  Future<void> delete(int listId, int userId) =>
      _dio.delete('/lists/$listId', queryParameters: {'userId': userId});

  Future<UserListSummary> addItem(int listId, int userId, TitleModel title) async {
    final response = await _dio.post('/lists/$listId/items', data: {
      'userId': userId,
      'tmdbId': title.tmdbId,
      'mediaType': title.mediaType.apiValue,
    });
    return UserListSummary.fromJson(response.data);
  }

  Future<void> removeItem(int listId, int userId, TitleModel title) =>
      _dio.delete('/lists/$listId/items/${title.tmdbId}', queryParameters: {
        'userId': userId,
        'mediaType': title.mediaType.apiValue,
      });
}
