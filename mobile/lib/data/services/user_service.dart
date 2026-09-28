import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = ApiClient.instance.dio;

  Future<UserModel> getById(int id) async {
    final response = await _dio.get('/users/$id');
    return UserModel.fromJson(response.data);
  }

  /// Throws a [DioException] with a 404 response if no account has this email.
  Future<UserModel> getByEmail(String email) async {
    final response = await _dio.get('/users/by-email', queryParameters: {'email': email});
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> createOrGet(String email, String displayName, String username) async {
    final response = await _dio.post('/users', data: {
      'email': email,
      'displayName': displayName,
      'username': username,
    });
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updatePreferredGenres(int userId, List<int> genreIds) async {
    final response = await _dio.put('/users/$userId/genres', data: {
      'genreIds': genreIds,
    });
    return UserModel.fromJson(response.data);
  }

  Future<List<UserSummaryModel>> search(String query, int excludeUserId) async {
    final response = await _dio.get('/users/search', queryParameters: {
      'query': query,
      'excludeUserId': excludeUserId,
    });
    return (response.data as List).map((e) => UserSummaryModel.fromJson(e)).toList();
  }

  Future<UserSummaryModel> getByFriendCode(String code) async {
    final response = await _dio.get('/users/by-code/$code');
    return UserSummaryModel.fromJson(response.data);
  }
}
