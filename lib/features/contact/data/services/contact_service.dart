import 'package:aarambha_app/core/constants/api_constants.dart';
import 'package:aarambha_app/core/network/api_client.dart';

class ContactService {
  final ApiClient _client;

  ContactService(this._client);

  Future<void> submitContact({
    required String name,
    required String email,
    required String message,
  }) async {
    await _client.post(
      ApiConstants.contact,
      data: {
        'name': name,
        'email': email,
        'message': message,
      },
    );
  }
}
