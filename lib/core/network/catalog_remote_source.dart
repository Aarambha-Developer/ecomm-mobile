import 'api_client.dart';
import '../constants/api_constants.dart';

class CatalogRemoteSource {
  final ApiClient _client;

  CatalogRemoteSource(this._client);

  Future<Map<String, dynamic>> getCategories({
    String? search,
    int page = 1,
  }) async {
    return await _client.get(
      ApiConstants.categories,
      queryParameters: {
        if (search != null) 'search': search,
        'page': page,
      },
    );
  }

  Future<Map<String, dynamic>> getBrands({
    String? search,
    int page = 1,
  }) async {
    return await _client.get(
      ApiConstants.brands,
      queryParameters: {
        if (search != null) 'search': search,
        'page': page,
      },
    );
  }

  Future<Map<String, dynamic>> getProducts({
    String? search,
    String? categorySlug,
    String? brandSlug,
    double? priceMin,
    double? priceMax,
    double? ratingMin,
    String? ordering,
    bool? isActive,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _client.get(
      ApiConstants.products,
      queryParameters: {
        if (search != null) 'search': search,
        if (categorySlug != null) 'category__slug': categorySlug,
        if (brandSlug != null) 'brand__slug': brandSlug,
        if (priceMin != null) 'price__gte': priceMin,
        if (priceMax != null) 'price__lte': priceMax,
        if (ratingMin != null) 'rating__gte': ratingMin,
        if (ordering != null) 'ordering': ordering,
        if (isActive != null) 'is_active': isActive,
        'page': page,
        'page_size': pageSize,
      },
    );
  }

  Future<Map<String, dynamic>> getProduct(String slug) async {
    return await _client.get('${ApiConstants.products}$slug/');
  }

  Future<Map<String, dynamic>> getProductReviews(String slug, {int page = 1}) async {
    return await _client.get(
      '${ApiConstants.products}$slug/reviews/',
      queryParameters: {'page': page},
    );
  }

  Future<Map<String, dynamic>> getHeroSlides() async {
    return await _client.get(ApiConstants.hero);
  }

  Future<Map<String, dynamic>> getActiveOffers() async {
    return await _client.get(
      ApiConstants.offers,
      queryParameters: {'is_active': true},
    );
  }
}
