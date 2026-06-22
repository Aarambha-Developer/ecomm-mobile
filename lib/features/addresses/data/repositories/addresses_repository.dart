import 'package:aarambha_app/features/addresses/data/datasources/addresses_remote_source.dart';
import 'package:aarambha_app/features/addresses/data/models/address.dart';

class AddressesRepository {
  final AddressesRemoteSource _remoteSource;

  AddressesRepository(this._remoteSource);

  Future<List<Address>> getAddresses() async {
    final response = await _remoteSource.getAddresses();
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Address.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Address> getAddress(String id) async {
    final response = await _remoteSource.getAddress(id);
    return Address.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Address> createAddress(Address address) async {
    final response = await _remoteSource.createAddress(address.toJson());
    return Address.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Address> updateAddress(String id, Address address) async {
    final response = await _remoteSource.updateAddress(id, address.toJson());
    return Address.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await _remoteSource.deleteAddress(id);
  }

  Future<Address> setDefaultAddress(String id) async {
    final response = await _remoteSource.setDefaultAddress(id);
    return Address.fromJson(response['data'] as Map<String, dynamic>);
  }
}
