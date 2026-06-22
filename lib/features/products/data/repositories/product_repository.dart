import '../../../../core/network/api_client.dart';
import '../../../../core/network/catalog_remote_source.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/product.dart';

class ProductRepository {
  final CatalogRemoteSource _remoteSource;

  ProductRepository(ApiClient client)
      : _remoteSource = CatalogRemoteSource(client);

  Future<ProductListResult> getProducts({
    String? search,
    String? categorySlug,
    String? brandSlug,
    double? priceMin,
    double? priceMax,
    double? ratingMin,
    String? ordering,
    int page = 1,
  }) async {
    final response = await _remoteSource.getProducts(
      search: search,
      categorySlug: categorySlug,
      brandSlug: brandSlug,
      priceMin: priceMin,
      priceMax: priceMax,
      ratingMin: ratingMin,
      ordering: ordering,
      page: page,
      pageSize: AppConstants.pageSize,
    );

    final data = response['data'];
    final pagination = response['pagination'] as Map<String, dynamic>?;

    List<Product> products = [];
    if (data is List) {
      products = data
          .whereType<Map<String, dynamic>>()
          .map((e) => Product.fromJson(e))
          .toList();
    }

    return ProductListResult(
      products: products,
      count: pagination?['count'] as int? ?? 0,
      next: pagination?['next'] as String?,
      previous: pagination?['previous'] as String?,
    );
  }

  Future<Product> getProduct(String slug) async {
    final response = await _remoteSource.getProduct(slug);
    final data = response['data'] as Map<String, dynamic>;
    return Product.fromJson(data);
  }
}

class ProductListResult {
  final List<Product> products;
  final int count;
  final String? next;
  final String? previous;

  const ProductListResult({
    required this.products,
    this.count = 0,
    this.next,
    this.previous,
  });

  bool get hasMore => next != null;
}
