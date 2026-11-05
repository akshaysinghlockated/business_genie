import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The sign-in token and when it runs out, kept in the Keychain (iOS) or
/// Keystore-backed storage (Android), never in plain preferences. Also
/// remembers the last email, to prefill the sign-in screen.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? secureStorage]) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Keeps everything in memory. For tests.
  TokenStorage.inMemory() : _secureStorage = null;

  static const _tokenKey = 'genie.token';
  static const _expiresAtKey = 'genie.token.expires';
  static const _lastEmailKey = 'genie.email';

  final FlutterSecureStorage? _secureStorage;
  final Map<String, String> _memory = {};

  String? _cachedToken;
  bool _hasReadToken = false;

  /// Read once, then served from memory (every request needs it).
  Future<String?> readToken() async {
    if (!_hasReadToken) {
      _cachedToken = await _read(_tokenKey);
      _hasReadToken = true;
    }
    return _cachedToken;
  }

  Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    _cachedToken = token;
    _hasReadToken = true;
    await _write(_tokenKey, token);
    if (expiresAt == null) {
      await _delete(_expiresAtKey);
    } else {
      await _write(_expiresAtKey, expiresAt.toUtc().toIso8601String());
    }
  }

  /// True once the stored expiry has passed. A token without one never expires here.
  Future<bool> isTokenExpired({DateTime? now}) async {
    final stored = await _read(_expiresAtKey);
    final expiresAt = stored == null ? null : DateTime.tryParse(stored);
    if (expiresAt == null) return false;
    return !(now ?? DateTime.now()).toUtc().isBefore(expiresAt);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _hasReadToken = true;
    await _delete(_tokenKey);
    await _delete(_expiresAtKey);
  }

  Future<String?> readLastEmail() => _read(_lastEmailKey);

  Future<void> saveLastEmail(String email) => _write(_lastEmailKey, email);

  Future<String?> _read(String key) async => _secureStorage == null ? _memory[key] : _secureStorage.read(key: key);

  Future<void> _write(String key, String value) async {
    final storage = _secureStorage;
    if (storage == null) {
      _memory[key] = value;
    } else {
      await storage.write(key: key, value: value);
    }
  }

  Future<void> _delete(String key) async {
    final storage = _secureStorage;
    if (storage == null) {
      _memory.remove(key);
    } else {
      await storage.delete(key: key);
    }
  }
}
