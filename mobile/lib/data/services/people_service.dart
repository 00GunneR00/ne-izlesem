import '../../core/network/api_client.dart';
import '../models/person_model.dart';
import '../models/title_model.dart';

class PeopleService {
  final _dio = ApiClient.instance.dio;

  Future<List<PersonModel>> search(String query, {int page = 1}) async {
    final response = await _dio.get(
      '/people/search',
      queryParameters: {'query': query, 'page': page},
    );
    return (response.data as List).map((e) => PersonModel.fromJson(e)).toList();
  }

  Future<List<PersonModel>> getPopular({int page = 1}) async {
    final response = await _dio.get(
      '/people/popular',
      queryParameters: {'page': page},
    );
    return (response.data as List).map((e) => PersonModel.fromJson(e)).toList();
  }

  Future<List<TitleModel>> getCredits(int personId) async {
    final response = await _dio.get('/people/$personId/credits');
    return (response.data as List).map((e) => TitleModel.fromJson(e)).toList();
  }
}
