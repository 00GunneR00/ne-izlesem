import '../../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/library_entry_model.dart';

class LibraryService {
  final _dio = ApiClient.instance.dio;

  Future<List<LibraryEntryModel>> getForUser(
    int userId, {
    LibraryStatus? status,
    MediaType? mediaType,
    int page = 1,
    int pageSize = 24,
  }) async {
    final response = await _dio.get(
      '/library',
      queryParameters: {
        'userId': userId,
        if (status != null) 'status': status.apiValue,
        if (mediaType != null) 'mediaType': mediaType.apiValue,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return (response.data as List)
        .map((e) => LibraryEntryModel.fromJson(e))
        .toList();
  }

  Future<int> getCount(int userId, {LibraryStatus? status}) async {
    final response = await _dio.get(
      '/library/count',
      queryParameters: {
        'userId': userId,
        if (status != null) 'status': status.apiValue,
      },
    );
    return response.data as int;
  }

  /// The user's entry for this title, or null if it isn't in their library.
  Future<LibraryEntryModel?> getEntry({
    required int userId,
    required int tmdbId,
    required MediaType mediaType,
  }) async {
    final response = await _dio.get(
      '/library/entry',
      queryParameters: {
        'userId': userId,
        'tmdbId': tmdbId,
        'mediaType': mediaType.apiValue,
      },
    );
    if (response.statusCode == 204 || response.data is! Map) return null;
    return LibraryEntryModel.fromJson(response.data);
  }

  Future<LibraryEntryModel> add({
    required int userId,
    required int tmdbId,
    required MediaType mediaType,
    required LibraryStatus status,
  }) async {
    final response = await _dio.post(
      '/library',
      data: {
        'userId': userId,
        'tmdbId': tmdbId,
        'mediaType': mediaType.apiValue,
        'status': status.apiValue,
      },
    );
    return LibraryEntryModel.fromJson(response.data);
  }

  Future<LibraryEntryModel> updateStatus(
    int entryId,
    LibraryStatus status,
  ) async {
    final response = await _dio.put(
      '/library/$entryId',
      data: {'status': status.apiValue},
    );
    return LibraryEntryModel.fromJson(response.data);
  }

  Future<void> remove(int entryId) => _dio.delete('/library/$entryId');

  /// 1–5 stars, or null to clear. Only allowed on watched entries.
  Future<LibraryEntryModel> setRating(int entryId, int userId, int? rating) async {
    final response = await _dio.put(
      '/library/$entryId/rating',
      data: {'userId': userId, 'rating': rating},
    );
    return LibraryEntryModel.fromJson(response.data);
  }
}
