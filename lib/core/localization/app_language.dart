import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppLanguage {
  french('fr'),
  english('en');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.english : AppLanguage.french;
}

final ValueNotifier<AppLanguage?> appLanguageNotifier = ValueNotifier(null);

class LanguageStorage {
  LanguageStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'perfomia_app_language';
  final FlutterSecureStorage _storage;

  Future<AppLanguage?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null || value.isEmpty) return null;
    return AppLanguage.fromCode(value);
  }

  Future<void> write(AppLanguage language) =>
      _storage.write(key: _key, value: language.code);
}
