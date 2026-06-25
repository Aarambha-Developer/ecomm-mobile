import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'package:aarambha_app/core/theme/app_colors.dart';
import 'package:aarambha_app/core/storage/local_cart_provider.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/core/widgets/product_card.dart';
import 'package:aarambha_app/features/categories/presentation/providers/category_provider.dart';
import 'package:aarambha_app/features/brands/presentation/providers/brand_provider.dart';
import 'package:aarambha_app/features/products/presentation/providers/product_provider.dart';
import 'package:aarambha_app/features/categories/data/models/category.dart';
import 'package:aarambha_app/features/brands/data/models/brand.dart';
import 'package:aarambha_app/features/home/presentation/providers/home_provider.dart';
import 'package:aarambha_app/features/home/data/models/home_models.dart';
import 'package:aarambha_app/features/cart/presentation/providers/cart_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).loadProducts(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final productsState = ref.watch(productListProvider);
    final heroAsync = ref.watch(heroSlidesProvider);
    final offersAsync = ref.watch(offersProvider);
    final storiesAsync = ref.watch(storyOffersProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(brandsProvider);
            ref.invalidate(heroSlidesProvider);
            ref.invalidate(offersProvider);
            ref.read(productListProvider.notifier).refresh();
            await Future.wait([
              ref.refresh(categoriesProvider.future),
              ref.refresh(brandsProvider.future),
              ref.refresh(heroSlidesProvider.future),
              ref.refresh(offersProvider.future),
            ]);
          },
          child: ListView(
            controller: _scrollController,
            children: [
              _HeroSection(heroAsync: heroAsync),
              const SizedBox(height: 12),
              _StoriesSection(storiesAsync: storiesAsync),
              const SizedBox(height: 12),
              _CategoriesSection(categoriesAsync: categoriesAsync),
              const SizedBox(height: 16),
              _OffersSection(offersAsync: offersAsync),
              const SizedBox(height: 16),
              _ProductsGrid(productsState: productsState),
              const SizedBox(height: 24),
              _BrandsSection(brandsAsync: brandsAsync),
              const SizedBox(height: 24),
              _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerStatefulWidget {
  final AsyncValue<HeroSection> heroAsync;

  const _HeroSection({required this.heroAsync});

  @override
  ConsumerState<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends ConsumerState<_HeroSection>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: 1, initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;
  late AnimationController _dotAnimController;
  int _displayedPage = 0;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _displayedPage) {
        setState(() => _displayedPage = page);
      }
    });
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _HeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final section = widget.heroAsync.valueOrNull;
      if (section == null || section.slides.isEmpty) return;
      final next = (_displayedPage + 1) % section.slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _dotAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.heroAsync.when(
      loading: () => _buildShimmer(),
      error: (_, _) => _buildStaticHero(context),
      data: (section) {
        if (section.slides.isNotEmpty) return _buildCarousel(section);
        return _buildStaticHero(context);
      },
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildCarousel(HeroSection section) {
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: section.slides.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
                _displayedPage = page;
              });
            },
            itemBuilder: (context, index) {
              final slide = section.slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSlide(context, section, slide),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(section.slides.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSlide(BuildContext context, HeroSection section, HeroSlide slide) {
    if (slide.image != null) {
      return GestureDetector(
        onTap: () => _handleSlideTap(section),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: slide.image!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _buildGradientSlide(section),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 80,
                bottom: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (section.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        section.subtitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildGradientSlide(section);
  }

  Widget _buildGradientSlide(HeroSection section) {
    return GestureDetector(
      onTap: () => _handleSlideTap(section),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
children: [
              const Icon(Icons.spa, color: Colors.white, size: 32),
              const SizedBox(height: 12),
                Text(
                  section.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (section.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    section.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSlideTap(HeroSection section) {
    final link = section.buttonLink;
    if (link != null) {
      if (link.startsWith('/')) {
        context.push(link);
      } else {
        context.push('/products');
      }
    }
  }

  Widget _buildStaticHero(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.spa, color: Colors.white, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Discover Beauty',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Curated skincare essentials for your daily glow',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.push('/products'),
                child: const Text('Shop Now',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesSection extends ConsumerWidget {
  final AsyncValue<List<Offer>> storiesAsync;

  const _StoriesSection({required this.storiesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewedStories = ref.watch(viewedStoriesProvider);

    return storiesAsync.when(
      loading: () => _sectionShimmer(
        title: 'Stories',
        height: 96,
        child: Row(
          children: List.generate(
            6,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (stories) {
        if (stories.isEmpty) return const SizedBox.shrink();

        return _SectionHeader(
          title: 'Stories',
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final story = stories[index];
                final imageUrl = story.image;
                final isViewed = viewedStories.contains(story.id);

                return GestureDetector(
                  onTap: () {
                    context.push(
                      '/stories',
                      extra: {
                        'stories': stories,
                        'initialIndex': index,
                      },
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isViewed
                                  ? Border.all(color: Colors.grey.shade300, width: 1.5)
                                  : null,
                              gradient: isViewed
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.primary, AppColors.accent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: isViewed ? 2 : 8,
                                  offset: Offset(0, isViewed ? 1 : 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: AppColors.surface,
                              child: ClipOval(
                                child: imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 66,
                                        height: 66,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => _storyFallback(),
                                      )
                                    : _storyFallback(),
                              ),
                            ),
                          ),
                          if (story.discountType != null && story.discountValue != null)
                            Positioned(
                              right: -4,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE5A93B), Color(0xFFC49030)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  story.discountType == 'percentage'
                                      ? '${story.discountValue! % 1 == 0 ? story.discountValue!.toInt() : story.discountValue}%'
                                      : '\$${story.discountValue! % 1 == 0 ? story.discountValue!.toInt() : story.discountValue}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 74,
                        child: Text(
                          story.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isViewed ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _storyFallback() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
      ),
    );
  }
}



class _CategoriesSection extends StatelessWidget {
  final AsyncValue<List<Category>> categoriesAsync;

  const _CategoriesSection({required this.categoriesAsync});

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      loading: () => _sectionShimmer(
        title: 'Categories',
        height: 100,
        child: Row(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 10,
                    color: AppColors.surface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return _SectionHeader(
          title: 'Shop by Category',
          onViewAll: () => context.push('/products'),
          child: SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () =>
                      context.push('/categories/${category.slug}'),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryLight,
                            image: category.image != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        category.image!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: category.image == null
                              ? const Icon(Icons.category,
                                  color: AppColors.primary, size: 28)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OffersSection extends StatelessWidget {
  final AsyncValue<List<Offer>> offersAsync;

  const _OffersSection({required this.offersAsync});

  @override
  Widget build(BuildContext context) {
    return offersAsync.when(
      loading: _buildLoading,
      error: (_, _) => const SizedBox.shrink(),
      data: (offers) {
        final visibleOffers =
            offers.where((offer) => offer.category != 'story').toList();
        if (visibleOffers.isEmpty) return const SizedBox.shrink();
        return _SectionHeader(
          title: 'Special Offers',
          child: SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visibleOffers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final offer = visibleOffers[index];
                return GestureDetector(
                  onTap: () => context.push('/products'),
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (offer.image != null)
                          SizedBox(
                            width: 110,
                            height: 150,
                            child: CachedNetworkImage(
                              imageUrl: offer.image!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const SizedBox(),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (offer.discountType != null && offer.discountValue != null) ...[
                                  _buildDiscountBadge(offer)!,
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  offer.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (offer.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    offer.description!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (offer.buttonText != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      offer.buttonText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget? _buildDiscountBadge(Offer offer) {
    if (offer.discountType == null || offer.discountValue == null) return null;
    final String text;
    if (offer.discountType == 'percentage') {
      final valStr = offer.discountValue! % 1 == 0 ? offer.discountValue!.toInt().toString() : offer.discountValue!.toString();
      text = '$valStr% OFF';
    } else if (offer.discountType == 'fixed') {
      final valStr = offer.discountValue! % 1 == 0 ? offer.discountValue!.toInt().toString() : offer.discountValue!.toString();
      text = 'Flat \$$valStr OFF';
    } else {
      return null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5A93B), Color(0xFFC49030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9.5,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return _sectionShimmer(
      title: 'Special Offers',
      height: 140,
      child: Row(
        children: List.generate(
          2,
          (_) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsGrid extends ConsumerWidget {
  final ProductListState productsState;

  const _ProductsGrid({required this.productsState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = productsState.products;

    if (productsState.isLoading && products.isEmpty) {
      return _sectionShimmer(
        title: 'Latest Products',
        height: 280,
        child: Row(
          children: List.generate(
            3,
            (_) => Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Latest Products',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length + (productsState.isLoadingMore ? 2 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.63,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index >= products.length) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              }
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('/products/${product.slug}'),
                onAddToCart: () {
                  ref.read(localCartProvider.notifier).addItem(
                        productId: product.id,
                        productName: product.name,
                        productImage: product.primaryImage,
                        price: product.discountedPrice > 0
                            ? product.discountedPrice
                            : product.price,
                        quantity: 1,
                      );
                  final authState = ref.read(authProvider);
                  if (authState.status == AuthStatus.authenticated) {
                    ref.read(cartProvider.notifier).addItem(
                          productId: product.id,
                          quantity: 1,
                        );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('${product.name} added to cart'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (productsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (productsState.error != null && products.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.textHint, size: 40),
                  const SizedBox(height: 8),
                  Text(productsState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BrandsSection extends StatelessWidget {
  final AsyncValue<List<Brand>> brandsAsync;

  const _BrandsSection({required this.brandsAsync});

  @override
  Widget build(BuildContext context) {
    return brandsAsync.when(
      loading: () => _sectionShimmer(
        title: 'Shop by Brand',
        height: 80,
        child: Row(
          children: List.generate(
            4,
            (_) => Container(
              width: 110,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (brands) {
        if (brands.isEmpty) return const SizedBox.shrink();
        return _SectionHeader(
          title: 'Shop by Brand',
          child: SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: brands.length.clamp(0, 8),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final brand = brands[index];
                return GestureDetector(
                  onTap: () => context.push('/brands/${brand.slug}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: brand.image != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: CachedNetworkImage(
                                imageUrl: brand.image!,
                                height: 28,
                                fit: BoxFit.contain,
                                errorWidget: (_, _, _) =>
                                    _brandText(brand),
                              ),
                            )
                          : _brandText(brand),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _brandText(Brand brand) {
    return Text(
      brand.title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    required this.child,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View all',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

Widget _sectionShimmer({
  required String title,
  required double height,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: height,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [child],
        ),
      ),
    ],
  );
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.spa_outlined,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lumora Nine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your trusted destination for authentic beauty products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '© 2026 Lumora Nine',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
