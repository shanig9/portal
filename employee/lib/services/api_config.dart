import 'package:flutter/foundation.dart';

/// One API endpoint for documents, applications, and reels.
class ApiConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredUrl.trim().isNotEmpty) return _configuredUrl.trim();
    if (kDebugMode) {
      return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:3000'
          : 'http://localhost:3000';
    }
    return '';
  }
}
