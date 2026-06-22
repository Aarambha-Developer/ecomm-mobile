import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class AddressesRemoteSource {
  final ApiClient _client;

  AddressesRemoteSource(this._client);

  Future<Map<String, dynamic>> getAddresses() async {
    return await _client.get(ApiConstants.addresses);
  }

  Future<Map<String, dynamic>> getAddress(String id) async {
    return await _client.get('${ApiConstants.addresses}$id/');
  }

  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> data) async {
    return await _client.post(ApiConstants.addresses, data: data);
  }

  Future<Map<String, dynamic>> updateAddress(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _client.put('${ApiConstants.addresses}$id/', data: data);
  }

  Future<void> deleteAddress(String id) async {
    await _client.delete('${ApiConstants.addresses}$id/');
  }

  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    return await _client.post(
      '${ApiConstants.addresses}$id/set_default/',
    );
  }
}
