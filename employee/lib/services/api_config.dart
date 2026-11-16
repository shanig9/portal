/// One API endpoint for documents, applications, and reels.
class ApiConfig {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredUrl.trim().isNotEmpty) return _configuredUrl.trim();
    return 'https://portal-server-go1e.vercel.app';
  }
}
