import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the customer access token securely across app launches so a
/// returning shopper stays signed in. The token is a credential, so it lives in
/// the platform keychain (iOS) / keystore (Android), never plain preferences.
///
/// An interface so tests can inject an in-memory fake instead of the platform
/// secure store.
abstract interface class AuthStorage {
  /// The saved access token, or `null` when signed out.
  Future<String?> readToken();

  /// When the saved token expires, or `null` when none is stored.
  Future<DateTime?> readExpiry();

  /// Persists [token] and its [expiresAt] as the active session.
  Future<void> write(String token, DateTime expiresAt);

  /// Forgets the session — on logout or once Shopify reports the token gone.
  Future<void> clear();
}

/// [AuthStorage] backed by `flutter_secure_storage`.
class SecureAuthStorage implements AuthStorage {
  const SecureAuthStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'customer_access_token';
  static const _expiryKey = 'customer_access_token_expires_at';

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<DateTime?> readExpiry() async {
    final raw = await _storage.read(key: _expiryKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> write(String token, DateTime expiresAt) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiryKey, value: expiresAt.toIso8601String());
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
  }
}
