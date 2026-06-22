import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_source.dart';
import '../models/auth_user.dart';

class AuthRepository {
  final AuthRemoteSource _remoteSource;
  final SecureStorage _storage;

  AuthRepository(ApiClient client)
      : _remoteSource = AuthRemoteSource(client),
        _storage = client.storage;

  Future<AuthUser> login(String email, String password) async {
    final response = await _remoteSource.login(email, password);
    final data = response['data'] as Map<String, dynamic>;

    final accessToken = data['access'] as String?;
    final refreshToken = data['refresh'] as String?;

    if (accessToken != null) {
      await _storage.saveAccessToken(accessToken);
    }
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }

    return AuthUser.fromJson(data);
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _remoteSource.register(
      email: email,
      password: password,
      phoneNumber: phoneNumber,
    );
    return AuthUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> googleLogin(String idToken) async {
    final response = await _remoteSource.googleLogin(idToken);
    final data = response['data'] as Map<String, dynamic>;

    final accessToken = data['access'] as String?;
    final refreshToken = data['refresh'] as String?;

    if (accessToken != null) {
      await _storage.saveAccessToken(accessToken);
    }
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }

    return AuthUser.fromJson(data);
  }

  Future<AuthUser> getProfile() async {
    final response = await _remoteSource.getProfile();
    final data = response['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data);
  }

  Future<bool> tryAutoLogin() async {
    final hasTokens = await _storage.hasTokens();
    if (!hasTokens) return false;
    try {
      await getProfile();
      return true;
    } catch (_) {
      await _storage.clearTokens();
      return false;
    }
  }

  Future<void> logout() async {
    await _remoteSource.logout();
    await _storage.clearTokens();
  }

  Future<void> requestPasswordReset(String contact) async {
    await _remoteSource.requestPasswordReset(contact);
  }

  Future<void> confirmPasswordReset({
    required String contact,
    required String otp,
    required String newPassword,
  }) async {
    await _remoteSource.confirmPasswordReset(
      contact: contact,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<void> verifyEmail(String otp) async {
    await _remoteSource.verifyEmail(otp);
  }

  Future<void> verifyPhone(String otp) async {
    await _remoteSource.verifyPhone(otp);
  }

  Future<AuthUser> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    final response = await _remoteSource.updateProfile(data);
    return AuthUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remoteSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
