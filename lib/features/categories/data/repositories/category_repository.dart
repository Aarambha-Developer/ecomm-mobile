import '../../../../core/network/api_client.dart';
import '../../../../core/network/catalog_remote_source.dart';
import '../models/category.dart';

class CategoryRepository {
  final CatalogRemoteSource _remoteSource;

  CategoryRepository(ApiClient client)
      : _remoteSource = CatalogRemoteSource(client);

  Future<List<Category>> getCategories({String? search}) async {
    final response = await _remoteSource.getCategories(search: search);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Category.fromJson(e))
          .toList();
    }
    return [];
  }
}
