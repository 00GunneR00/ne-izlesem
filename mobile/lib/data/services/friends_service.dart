import '../../core/network/api_client.dart';
import '../models/friend_model.dart';

class FriendsService {
  final _dio = ApiClient.instance.dio;

  Future<void> sendRequestByUsername(int requesterId, String username) => _dio.post('/friends/requests', data: {
        'requesterId': requesterId,
        'username': username,
      });

  Future<void> sendRequestByFriendCode(int requesterId, String friendCode) => _dio.post('/friends/requests', data: {
        'requesterId': requesterId,
        'friendCode': friendCode,
      });

  Future<List<FriendRequestModel>> getIncomingRequests(int userId) async {
    final response = await _dio.get('/friends/requests', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => FriendRequestModel.fromJson(e)).toList();
  }

  Future<void> markRequestsSeen(int userId) =>
      _dio.post('/friends/requests/mark-seen', queryParameters: {'userId': userId});

  Future<void> accept(int friendshipId, int userId) =>
      _dio.post('/friends/requests/$friendshipId/accept', queryParameters: {'userId': userId});

  Future<void> decline(int friendshipId, int userId) =>
      _dio.post('/friends/requests/$friendshipId/decline', queryParameters: {'userId': userId});

  Future<List<FriendModel>> getFriends(int userId) async {
    final response = await _dio.get('/friends', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => FriendModel.fromJson(e)).toList();
  }

  Future<void> remove(int friendshipId, int userId) =>
      _dio.delete('/friends/$friendshipId', queryParameters: {'userId': userId});
}
