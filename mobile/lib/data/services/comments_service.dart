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
  }) async {
    final response = await _dio.post('/comments', data: {
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType.apiValue,
      'text': text,
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
}
