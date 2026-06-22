import '../../../../core/network/api_client.dart';
import '../../../../core/network/catalog_remote_source.dart';
import '../models/brand.dart';

class BrandRepository {
  final CatalogRemoteSource _remoteSource;

  BrandRepository(ApiClient client)
      : _remoteSource = CatalogRemoteSource(client);

  Future<List<Brand>> getBrands({String? search}) async {
    final response = await _remoteSource.getBrands(search: search);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Brand.fromJson(e))
          .toList();
    }
    return [];
  }
}
