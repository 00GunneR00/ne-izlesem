import '../../core/network/api_client.dart';
import '../models/enums.dart';

class LikedTitleKey {
  final int tmdbId;
  final MediaType mediaType;
  LikedTitleKey(this.tmdbId, this.mediaType);

  factory LikedTitleKey.fromJson(Map<String, dynamic> json) => LikedTitleKey(
        json['tmdbId'] as int,
        MediaType.fromApi(json['mediaType'] as String),
      );
}

class LikesService {
  final _dio = ApiClient.instance.dio;

  Future<bool> toggle({required int userId, required int tmdbId, required MediaType mediaType}) async {
    final response = await _dio.post('/likes/toggle', data: {
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType.apiValue,
    });
    return response.data['liked'] as bool;
  }

  Future<List<LikedTitleKey>> getForUser(int userId) async {
    final response = await _dio.get('/likes', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => LikedTitleKey.fromJson(e)).toList();
  }

  Future<Map<int, int>> getCounts(List<int> tmdbIds, MediaType mediaType) async {
    if (tmdbIds.isEmpty) return {};
    final response = await _dio.get('/likes/counts', queryParameters: {
      'tmdbIds': tmdbIds.join(','),
      'mediaType': mediaType.apiValue,
    });
    return {for (final e in response.data as List) e['tmdbId'] as int: e['count'] as int};
  }
}
