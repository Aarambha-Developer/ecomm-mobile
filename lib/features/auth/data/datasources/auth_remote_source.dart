import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRemoteSource {
  final ApiClient _client;

  AuthRemoteSource(this._client);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final isEmail = username.contains('@');
    return await _client.post(
      ApiConstants.login,
      data: {
        isEmail ? 'email' : 'phone_number': username,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    return await _client.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    return await _client.post(
      ApiConstants.googleLogin,
      data: {'id_token': idToken},
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await _client.get(ApiConstants.me);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _client.post(
      ApiConstants.refreshToken,
      data: {'refresh_token': refreshToken},
    );
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> requestPasswordReset(String contact) async {
    return await _client.post(
      ApiConstants.passwordResetRequest,
      data: {
        if (contact.contains('@')) 'email': contact else 'phone_number': contact,
      },
    );
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String contact,
    required String otp,
    required String newPassword,
  }) async {
    return await _client.post(
      ApiConstants.passwordResetConfirm,
      data: {
        if (contact.contains('@')) 'email': contact else 'phone_number': contact,
        'otp': otp,
        'new_password': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> verifyEmail(String otp) async {
    return await _client.post(
      ApiConstants.verifyEmail,
      data: {'otp': otp},
    );
  }

  Future<Map<String, dynamic>> verifyPhone(String otp) async {
    return await _client.post(
      ApiConstants.verifyPhone,
      data: {'otp': otp},
    );
  }

  Future<Map<String, dynamic>> resendVerification() async {
    return await _client.post(ApiConstants.resendVerification);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await _client.put(ApiConstants.me, data: data);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _client.post(
      ApiConstants.changePassword,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      },
    );
  }
}
