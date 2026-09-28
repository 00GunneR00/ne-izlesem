import '../../core/network/api_client.dart';
import '../models/tracking_model.dart';

class TrackingService {
  final _dio = ApiClient.instance.dio;

  Future<TrackingModel> get(int userId) async {
    final response = await _dio.get('/tracking', queryParameters: {'userId': userId});
    return TrackingModel.fromJson(response.data);
  }
}
