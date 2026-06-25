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
    double? discountMin,
    int? stockMin,
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
      discountMin: discountMin,
      stockMin: stockMin,
      ordering: ordering,
      page: page,
      pageSize: AppConstants.pageSize,
    );

    final data = response['data'];
    final pagination = response['pagination'] != null ? Map<String, dynamic>.from(response['pagination'] as Map) : null;

    List<Product> products = [];
    if (data is List) {
      products = data
          .map((e) => e is Map ? Product.fromJson(Map<String, dynamic>.from(e)) : null)
          .whereType<Product>()
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
    final data = Map<String, dynamic>.from(response['data'] as Map);
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
