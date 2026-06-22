import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/brand_repository.dart';
import '../../data/models/brand.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository(ref.read(apiClientProvider));
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final repo = ref.read(brandRepositoryProvider);
  return await repo.getBrands();
});
