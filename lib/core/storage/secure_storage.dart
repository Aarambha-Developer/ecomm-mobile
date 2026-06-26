import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

class SecureStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {}
  }

  Future<bool> hasTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    return access != null;
  }

  Future<void> saveFullName(String emailOrId, String name) async {
    await _storage.write(key: 'user_fullname_$emailOrId', value: name);
  }

  Future<String?> getFullName(String emailOrId) async {
    return await _storage.read(key: 'user_fullname_$emailOrId');
  }

  Future<void> clearFullName(String emailOrId) async {
    try {
      await _storage.delete(key: 'user_fullname_$emailOrId');
    } catch (_) {}
  }
}
