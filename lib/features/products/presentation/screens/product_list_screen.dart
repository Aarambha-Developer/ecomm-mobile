import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/widgets/product_card.dart';
import 'package:aarambha_app/core/widgets/loading_widget.dart';
import 'package:aarambha_app/core/widgets/error_view.dart';
import 'package:aarambha_app/core/widgets/empty_state.dart';
import 'package:aarambha_app/features/products/presentation/providers/product_provider.dart';
import 'package:aarambha_app/features/categories/presentation/providers/category_provider.dart';
import 'package:aarambha_app/features/brands/presentation/providers/brand_provider.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? initialCategorySlug;
  final String? initialBrandSlug;
  final String? initialSearch;

  const ProductListScreen({
    super.key,
    this.initialCategorySlug,
    this.initialBrandSlug,
    this.initialSearch,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedOrdering;
  double? _priceMin;
  double? _priceMax;
  double? _ratingMin;
  double? _discountMin;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filters = ProductFilters(
        search: widget.initialSearch,
        categorySlug: widget.initialCategorySlug,
        brandSlug: widget.initialBrandSlug,
      );
      ref.read(productListProvider.notifier).setFilters(filters);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  void _onSearch(String query) {
    ref.read(productListProvider.notifier).setSearch(
          query.isEmpty ? null : query,
        );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FilterSheet(
        initialCategorySlug: widget.initialCategorySlug,
        initialBrandSlug: widget.initialBrandSlug,
        initialPriceMin: _priceMin,
        initialPriceMax: _priceMax,
        initialRatingMin: _ratingMin,
        initialDiscountMin: _discountMin,
        onApply: (categorySlug, brandSlug, priceMin, priceMax,
            ratingMin, discountMin) {
          setState(() {
            _priceMin = priceMin;
            _priceMax = priceMax;
            _ratingMin = ratingMin;
            _discountMin = discountMin;
          });
          ref.read(productListProvider.notifier).setFilters(
                ProductFilters(
                  search: _searchController.text.isNotEmpty
                      ? _searchController.text
                      : null,
                  categorySlug: categorySlug,
                  brandSlug: brandSlug,
                  priceMin: priceMin,
                  priceMax: priceMax,
                  ratingMin: ratingMin,
                  discountMin: discountMin,
                  ordering: _selectedOrdering,
                ),
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialCategorySlug ?? widget.initialBrandSlug ?? 'Products',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onSubmitted: _onSearch,
            onClear: () {
              _searchController.clear();
              _onSearch('');
            },
          ),
          if (state.totalCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${state.totalCount} products',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _SortDropdown(
                    value: _selectedOrdering,
                    onChanged: (v) {
                      setState(() => _selectedOrdering = v);
                      ref.read(productListProvider.notifier).setOrdering(v);
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const LoadingWidget(message: 'Loading products...');
    }

    if (state.error != null && state.products.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(productListProvider.notifier).refresh(),
      );
    }

    if (state.products.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No products found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(productListProvider.notifier).refresh();
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final product = state.products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push('/products/${product.slug}'),
            onAddToCart: () {
              ref.read(cartProvider.notifier).addItem(
                    productId: product.id,
                    quantity: 1,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added to cart')),
              );
            },
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: value,
        hint: const Text('Newest', style: TextStyle(fontSize: 13)),
        icon: const Icon(Icons.arrow_drop_down, size: 18),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: const [
          DropdownMenuItem(value: null, child: Text('Newest')),
          DropdownMenuItem(value: 'price', child: Text('Price: Low to High')),
          DropdownMenuItem(value: '-price', child: Text('Price: High to Low')),
          DropdownMenuItem(value: '-rating', child: Text('Top Rated')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final String? initialCategorySlug;
  final String? initialBrandSlug;
  final double? initialPriceMin;
  final double? initialPriceMax;
  final double? initialRatingMin;
  final double? initialDiscountMin;
  final void Function(String? categorySlug, String? brandSlug,
      double? priceMin, double? priceMax, double? ratingMin, double? discountMin) onApply;

  const _FilterSheet({
    this.initialCategorySlug,
    this.initialBrandSlug,
    this.initialPriceMin,
    this.initialPriceMax,
    this.initialRatingMin,
    this.initialDiscountMin,
    required this.onApply,
  });

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _selectedCategory;
  String? _selectedBrand;
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  double _ratingMin = 0;
  double _discountMin = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategorySlug;
    _selectedBrand = widget.initialBrandSlug;
    if (widget.initialPriceMin != null) {
      _priceMinController.text = widget.initialPriceMin.toString();
    }
    if (widget.initialPriceMax != null) {
      _priceMaxController.text = widget.initialPriceMax.toString();
    }
    _ratingMin = widget.initialRatingMin ?? 0;
    _discountMin = widget.initialDiscountMin ?? 0;
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedBrand = null;
                          _priceMinController.clear();
                          _priceMaxController.clear();
                          _ratingMin = 0;
                          _discountMin = 0;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final selected = _selectedCategory == cat.slug;
                      return FilterChip(
                        label: Text(cat.name),
                        selected: selected,
                        onSelected: (sel) {
                          setState(() {
                            _selectedCategory = sel ? cat.slug : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (_, _) => const Text('Failed to load categories'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Brand',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                brandsAsync.when(
                  data: (brands) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: brands.map((brand) {
                      final selected = _selectedBrand == brand.slug;
                      return FilterChip(
                        label: Text(brand.title),
                        selected: selected,
                        onSelected: (sel) {
                          setState(() {
                            _selectedBrand = sel ? brand.slug : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (_, _) => const Text('Failed to load brands'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Price Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          hintText: '0',
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _priceMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          hintText: '10000',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Minimum Rating',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _ratingMin,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _ratingMin > 0 ? '${_ratingMin.round()}+ stars' : 'Any',
                        onChanged: (v) => setState(() => _ratingMin = v),
                      ),
                    ),
                    Text(
                      _ratingMin > 0 ? '${_ratingMin.round()}+ stars' : 'Any',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Minimum Discount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _discountMin,
                        min: 0,
                        max: 100,
                        divisions: 10,
                        label: _discountMin > 0 ? '${_discountMin.round()}%+ off' : 'Any',
                        onChanged: (v) => setState(() => _discountMin = v),
                      ),
                    ),
                    Text(
                      _discountMin > 0 ? '${_discountMin.round()}% off' : 'Any',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
onPressed: () {
                    final priceMin = double.tryParse(_priceMinController.text);
                    final priceMax = double.tryParse(_priceMaxController.text);
                    widget.onApply(
                      _selectedCategory,
                      _selectedBrand,
                      priceMin,
                      priceMax,
                      _ratingMin > 0 ? _ratingMin : null,
                      _discountMin > 0 ? _discountMin : null,
                    );
                    Navigator.of(context).pop();
                  },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
