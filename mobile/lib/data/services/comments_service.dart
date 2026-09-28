import '../../core/network/api_client.dart';
import '../models/comment_model.dart';
import '../models/enums.dart';

class CommentsService {
  final _dio = ApiClient.instance.dio;

  Future<CommentModel> add({
    required int userId,
    required int tmdbId,
    required MediaType mediaType,
    required String text,
    bool isSpoiler = false,
  }) async {
    final response = await _dio.post('/comments', data: {
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType.apiValue,
      'text': text,
      'isSpoiler': isSpoiler,
    });
    return CommentModel.fromJson(response.data);
  }

  Future<List<CommentModel>> getForTitle(int tmdbId, MediaType mediaType) async {
    final response = await _dio.get('/comments', queryParameters: {
      'tmdbId': tmdbId,
      'mediaType': mediaType.apiValue,
    });
    return (response.data as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  /// Author only.
  Future<CommentModel> update(
    int commentId, {
    required int userId,
    required String text,
    required bool isSpoiler,
  }) async {
    final response = await _dio.put('/comments/$commentId', data: {
      'userId': userId,
      'text': text,
      'isSpoiler': isSpoiler,
    });
    return CommentModel.fromJson(response.data);
  }

  /// Author only.
  Future<void> delete(int commentId, int userId) =>
      _dio.delete('/comments/$commentId', queryParameters: {'userId': userId});
}
