import '../../core/network/api_client.dart';
import '../models/plan_model.dart';
import '../models/title_model.dart';

class PlansService {
  final _dio = ApiClient.instance.dio;

  /// Upcoming plans plus those from the last two weeks, soonest first.
  Future<List<PlanModel>> getForUser(int userId) async {
    final response = await _dio.get('/plans', queryParameters: {'userId': userId});
    return (response.data as List).map((e) => PlanModel.fromJson(e)).toList();
  }

  /// Solo when neither [groupId] nor [friendIds] is given.
  Future<PlanModel> create({
    required int userId,
    required TitleModel title,
    required DateTime scheduledAt,
    int? groupId,
    List<int>? friendIds,
    String? note,
  }) async {
    final response = await _dio.post('/plans', data: {
      'userId': userId,
      'tmdbId': title.tmdbId,
      'mediaType': title.mediaType.apiValue,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'groupId': groupId,
      'friendIds': friendIds,
      'note': note,
    });
    return PlanModel.fromJson(response.data);
  }

  Future<PlanModel> respond(int planId, int userId, PlanResponse response) async {
    final res = await _dio.post('/plans/$planId/respond', queryParameters: {
      'userId': userId,
      'response': response.apiValue,
    });
    return PlanModel.fromJson(res.data);
  }

  /// "Nasıldı?" — Watched also adds it to the library.
  Future<PlanModel> setOutcome(int planId, int userId, PlanOutcome outcome) async {
    final res = await _dio.post('/plans/$planId/outcome', queryParameters: {
      'userId': userId,
      'outcome': outcome.apiValue,
    });
    return PlanModel.fromJson(res.data);
  }

  /// Creator only.
  Future<void> cancel(int planId, int userId) =>
      _dio.delete('/plans/$planId', queryParameters: {'userId': userId});
}
