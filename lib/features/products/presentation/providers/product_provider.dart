import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(apiClientProvider));
});

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, slug) async {
  final repo = ref.read(productRepositoryProvider);
  return await repo.getProduct(slug);
});

class ProductFilters {
  final String? search;
  final String? categorySlug;
  final String? brandSlug;
  final double? priceMin;
  final double? priceMax;
  final String? ordering;

  const ProductFilters({
    this.search,
    this.categorySlug,
    this.brandSlug,
    this.priceMin,
    this.priceMax,
    this.ordering,
  });

  ProductFilters copyWith({
    String? search,
    String? categorySlug,
    String? brandSlug,
    double? priceMin,
    double? priceMax,
    String? ordering,
    bool clearSearch = false,
    bool clearCategory = false,
    bool clearBrand = false,
    bool clearPrice = false,
  }) {
    return ProductFilters(
      search: clearSearch ? null : (search ?? this.search),
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
      brandSlug: clearBrand ? null : (brandSlug ?? this.brandSlug),
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
      ordering: ordering ?? this.ordering,
    );
  }
}

class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalCount;
  final String? error;
  final ProductFilters filters;
  final int currentPage;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.totalCount = 0,
    this.error,
    this.filters = const ProductFilters(),
    this.currentPage = 1,
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalCount,
    String? error,
    ProductFilters? filters,
    int? currentPage,
    bool clearError = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductRepository _repository;

  ProductListNotifier(this._repository) : super(const ProductListState());

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: refresh ? state.error : null,
      products: refresh ? [] : state.products,
      currentPage: refresh ? 1 : state.currentPage,
    );

    try {
      final result = await _repository.getProducts(
        search: state.filters.search,
        categorySlug: state.filters.categorySlug,
        brandSlug: state.filters.brandSlug,
        priceMin: state.filters.priceMin,
        priceMax: state.filters.priceMax,
        ordering: state.filters.ordering,
        page: refresh ? 1 : state.currentPage,
      );

      state = state.copyWith(
        products: refresh ? result.products : [...state.products, ...result.products],
        isLoading: false,
        hasMore: result.hasMore,
        totalCount: result.count,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final result = await _repository.getProducts(
        search: state.filters.search,
        categorySlug: state.filters.categorySlug,
        brandSlug: state.filters.brandSlug,
        priceMin: state.filters.priceMin,
        priceMax: state.filters.priceMax,
        ordering: state.filters.ordering,
        page: nextPage,
      );

      state = state.copyWith(
        products: [...state.products, ...result.products],
        isLoadingMore: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void setFilters(ProductFilters filters) {
    state = state.copyWith(filters: filters);
    loadProducts(refresh: true);
  }

  void setSearch(String? query) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        search: query,
        clearSearch: query == null,
      ),
    );
    loadProducts(refresh: true);
  }

  void setOrdering(String? ordering) {
    state = state.copyWith(
      filters: state.filters.copyWith(ordering: ordering),
    );
    loadProducts(refresh: true);
  }

  void refresh() {
    loadProducts(refresh: true);
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  final repo = ref.read(productRepositoryProvider);
  return ProductListNotifier(repo);
});
