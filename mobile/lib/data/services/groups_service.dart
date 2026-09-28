import '../../core/network/api_client.dart';
import '../models/group_model.dart';
import '../models/suggestion_model.dart';

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

  Future<List<GroupWatchlistItem>> getWatchlist(int groupId, int userId) async {
    final response = await _dio.get('/groups/$groupId/watchlist', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => GroupWatchlistItem.fromJson(e)).toList();
  }
}
