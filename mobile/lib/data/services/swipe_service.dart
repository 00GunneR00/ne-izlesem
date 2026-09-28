import '../../core/network/api_client.dart';
import '../models/enums.dart';

class SwipeService {
  final _dio = ApiClient.instance.dio;

  Future<void> record({
    required int userId,
    required int tmdbId,
    required MediaType mediaType,
    required SwipeDirection direction,
  }) {
    return _dio.post('/swipes', data: {
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType.apiValue,
      'direction': direction.apiValue,
    });
  }
}
