import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'perfomia_access_token';
  static const _userKey = 'perfomia_cached_user';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> saveUser(Map<String, dynamic> user) =>
      _storage.write(key: _userKey, value: jsonEncode(user));

  Future<Map<String, dynamic>?> readUser() async {
    final value = await _storage.read(key: _userKey);
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
