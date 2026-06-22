import '../../../../core/network/catalog_remote_source.dart';
import '../models/home_models.dart';

class HomeRepository {
  final CatalogRemoteSource _remoteSource;

  HomeRepository(CatalogRemoteSource remoteSource)
      : _remoteSource = remoteSource;

  Future<List<HeroSlide>> getHeroSlides() async {
    final response = await _remoteSource.getHeroSlides();
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => HeroSlide.fromJson(e))
          .where((s) => s.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return [];
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
}
