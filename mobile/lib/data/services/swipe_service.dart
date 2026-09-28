import '../../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/title_model.dart';

class SwipeDeck {
  final List<TitleModel> items;
  final int nextPage;

  SwipeDeck({required this.items, required this.nextPage});

  factory SwipeDeck.fromJson(Map<String, dynamic> json) => SwipeDeck(
        items: (json['items'] as List).map((e) => TitleModel.fromJson(e)).toList(),
        nextPage: json['nextPage'] as int,
      );
}

class SwipeService {
  final _dio = ApiClient.instance.dio;

  /// Cards in the user's preferred genres, minus anything they already
  /// swiped or have in their library (filtered server-side).
  Future<SwipeDeck> getDeck({
    required int userId,
    required MediaType mediaType,
    required int page,
  }) async {
    final response = await _dio.get('/swipes/deck', queryParameters: {
      'userId': userId,
      'mediaType': mediaType.apiValue,
      'page': page,
    });
    return SwipeDeck.fromJson(response.data);
  }

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
