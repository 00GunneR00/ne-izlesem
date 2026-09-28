import '../../core/network/api_client.dart';
import '../models/feed_item_model.dart';

class FeedService {
  final _dio = ApiClient.instance.dio;

  Future<List<FeedItemModel>> getFeed(int userId, {int take = 30}) async {
    final response = await _dio.get('/feed', queryParameters: {'userId': userId, 'take': take});
    return (response.data as List).map((e) => FeedItemModel.fromJson(e)).toList();
  }
}
