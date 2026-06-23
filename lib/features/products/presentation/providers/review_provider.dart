import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/core/network/catalog_remote_source.dart';
import 'package:aarambha_app/features/products/data/models/product.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ReviewRepository(CatalogRemoteSource(apiClient));
});

class ReviewRepository {
  final CatalogRemoteSource _remoteSource;

  ReviewRepository(this._remoteSource);

  Future<List<ProductReview>> getReviews(String slug, {int page = 1}) async {
    final response = await _remoteSource.getProductReviews(slug, page: page);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => ProductReview.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<ProductReview> submitReview(
    String slug, {
    required int rating,
    required String comment,
  }) async {
    final response = await _remoteSource.postProductReview(
      slug,
      rating: rating,
      comment: comment,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProductReview.fromJson(data);
  }
}

final productReviewsProvider =
    FutureProvider.family<List<ProductReview>, String>((ref, slug) async {
  final repo = ref.read(reviewRepositoryProvider);
  return await repo.getReviews(slug);
});
