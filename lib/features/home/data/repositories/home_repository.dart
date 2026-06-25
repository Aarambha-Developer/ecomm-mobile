import '../../../../core/network/catalog_remote_source.dart';
import '../models/home_models.dart';

class HomeRepository {
  final CatalogRemoteSource _remoteSource;

  HomeRepository(CatalogRemoteSource remoteSource)
      : _remoteSource = remoteSource;

  Future<HeroSection> getHeroSection() async {
    final response = await _remoteSource.getHeroSlides();
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final section = HeroSection.fromJson(data);
      final activeSlides =
          section.slides.where((s) => s.isActive).toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return HeroSection(
        id: section.id,
        title: section.title,
        subtitle: section.subtitle,
        description: section.description,
        buttonLabel: section.buttonLabel,
        buttonLink: section.buttonLink,
        slides: activeSlides,
      );
    }
    return const HeroSection(id: 0, title: '');
  }

  Future<List<Offer>> getActiveOffers() async {
    final response = await _remoteSource.getActiveOffers();
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Offer.fromJson(e))
          .where((o) => o.isActive)
          .toList();
    }
    return [];
  }

  Future<List<Offer>> getStories() async {
    final response = await _remoteSource.getStories();
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Offer.fromJson(e))
          .where((o) => o.isActive)
          .toList();
    }
    return [];
  }
}
