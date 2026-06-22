import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/core/network/catalog_remote_source.dart';
import 'package:aarambha_app/features/home/data/repositories/home_repository.dart';
import 'package:aarambha_app/features/home/data/models/home_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return HomeRepository(CatalogRemoteSource(apiClient));
});

final heroSlidesProvider = FutureProvider<List<HeroSlide>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return await repo.getHeroSlides();
});

final offersProvider = FutureProvider<List<Offer>>((ref) async {
  final repo = ref.read(homeRepositoryProvider);
  return await repo.getActiveOffers();
});
