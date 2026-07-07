import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AdConfig {
  final String bannerUrl;
  final double height;

  const AdConfig({
    required this.bannerUrl,
    this.height = 48,
  });
}

class AdConfigService {
  AdConfigService._();

  static AdConfig? _cached;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 15);

  static Future<AdConfig?> loadBannerConfig({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cached;
    }

    try {
      final response = await http
          .get(Uri.parse(AppConfig.adConfigUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final bannerUrl = (data['banner_url'] ?? data['url'] ?? AppConfig.defaultAdBannerUrl)
          .toString()
          .trim();
      if (bannerUrl.isEmpty) return null;

      final height = (data['height'] as num?)?.toDouble() ?? 48;
      _cached = AdConfig(bannerUrl: bannerUrl, height: height);
      _cachedAt = DateTime.now();
      return _cached;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _cached = null;
    _cachedAt = null;
  }
}
