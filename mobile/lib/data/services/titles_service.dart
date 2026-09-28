import '../../core/network/api_client.dart';
import '../models/cast_member_model.dart';
import '../models/enums.dart';
import '../models/genre_model.dart';
import '../models/season_model.dart';
import '../models/title_model.dart';
import '../models/trailer_model.dart';

class TitlesService {
  final _dio = ApiClient.instance.dio;

  Future<List<GenreModel>> getGenres(MediaType mediaType) async {
    final response = await _dio.get(
      '/titles/genres',
      queryParameters: {'mediaType': mediaType.apiValue},
    );
    return (response.data as List).map((e) => GenreModel.fromJson(e)).toList();
  }

  Future<List<TitleModel>> getTrending(
    MediaType mediaType, {
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/titles/trending',
      queryParameters: {'mediaType': mediaType.apiValue, 'page': page},
    );
    return (response.data as List).map((e) => TitleModel.fromJson(e)).toList();
  }

  Future<List<TitleModel>> discover(
    MediaType mediaType, {
    int? genreId,
    int page = 1,
    int? providerId,
  }) async {
    final response = await _dio.get(
      '/titles/discover',
      queryParameters: {
        'mediaType': mediaType.apiValue,
        if (genreId != null) 'genreId': genreId,
        if (providerId != null) 'providerId': providerId,
        'page': page,
      },
    );
    return (response.data as List).map((e) => TitleModel.fromJson(e)).toList();
  }

  /// Aired seasons of a show (no specials).
  Future<List<SeasonModel>> getSeasons(int tmdbId) async {
    final response = await _dio.get('/titles/Show/$tmdbId/seasons');
    return (response.data as List).map((e) => SeasonModel.fromJson(e)).toList();
  }

  /// "Senin İçin": titles similar to what the user rated/liked/watched.
  /// Returns the items plus the seed titles they're based on (empty when
  /// the backend fell back to preferred genres).
  Future<({List<TitleModel> items, List<String> basedOn})> getRecommendations(
    int userId,
    MediaType mediaType,
  ) async {
    final response = await _dio.get(
      '/recommendations',
      queryParameters: {'userId': userId, 'mediaType': mediaType.apiValue},
    );
    return (
      items: (response.data['items'] as List)
          .map((e) => TitleModel.fromJson(e))
          .toList(),
      basedOn: (response.data['basedOn'] as List).cast<String>(),
    );
  }

  Future<List<TitleModel>> search(
    MediaType mediaType,
    String query, {
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/titles/search',
      queryParameters: {
        'mediaType': mediaType.apiValue,
        'query': query,
        'page': page,
      },
    );
    return (response.data as List).map((e) => TitleModel.fromJson(e)).toList();
  }

  Future<TitleModel> getDetails(MediaType mediaType, int tmdbId) async {
    final response = await _dio.get('/titles/${mediaType.apiValue}/$tmdbId');
    return TitleModel.fromJson(response.data);
  }

  Future<List<CastMemberModel>> getCast(MediaType mediaType, int tmdbId) async {
    final response = await _dio.get(
      '/titles/${mediaType.apiValue}/$tmdbId/cast',
    );
    return (response.data as List)
        .map((e) => CastMemberModel.fromJson(e))
        .toList();
  }

  Future<List<TrailerModel>> getTrailers(
    MediaType mediaType,
    int tmdbId,
  ) async {
    final response = await _dio.get(
      '/titles/${mediaType.apiValue}/$tmdbId/trailers',
    );
    return (response.data as List)
        .map((e) => TrailerModel.fromJson(e))
        .toList();
  }

  /// Checks trailer availability for a whole batch of titles in one request,
  /// so the discover feed can deprioritize trailer-less titles without
  /// firing one HTTP call per title.
  Future<Map<int, bool>> getTrailerStatus(
    MediaType mediaType,
    List<int> tmdbIds,
  ) async {
    if (tmdbIds.isEmpty) return {};
    final response = await _dio.get(
      '/titles/trailer-status',
      queryParameters: {
        'mediaType': mediaType.apiValue,
        'tmdbIds': tmdbIds.join(','),
      },
    );
    return (response.data as Map<String, dynamic>).map(
      (key, value) => MapEntry(int.parse(key), value as bool),
    );
  }
}
