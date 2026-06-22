import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aarambha_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:aarambha_app/features/addresses/data/repositories/addresses_repository.dart';
import 'package:aarambha_app/features/addresses/data/datasources/addresses_remote_source.dart';
import 'package:aarambha_app/features/addresses/data/models/address.dart';

final addressesRepositoryProvider = Provider<AddressesRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AddressesRepository(AddressesRemoteSource(apiClient));
});

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  final repo = ref.read(addressesRepositoryProvider);
  return await repo.getAddresses();
});
