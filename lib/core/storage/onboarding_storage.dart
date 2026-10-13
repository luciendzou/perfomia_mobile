import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingStorage {
  OnboardingStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _completedKey = 'perfomia_onboarding_completed';
  final FlutterSecureStorage _storage;

  Future<bool> isCompleted() async =>
      await _storage.read(key: _completedKey) == 'true';

  Future<void> markCompleted() =>
      _storage.write(key: _completedKey, value: 'true');
}
