import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const _apiOverride = String.fromEnvironment(
    'PERFOMIA_API_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiOverride.isNotEmpty) return _apiOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static const deviceName = String.fromEnvironment(
    'PERFOMIA_DEVICE_NAME',
    defaultValue: 'perfomia-mobile',
  );
}
