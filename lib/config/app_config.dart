/// Remote endpoints and feature flags for LingoStream AI.
class AppConfig {
  AppConfig._();

  /// JSON config served by your server: {"banner_url":"https://...","height":48}
  static const String adConfigUrl =
      'https://your-server.com/lingostream/ad-config.json';

  /// Fallback HTML banner URL if config fetch fails but internet works.
  static const String defaultAdBannerUrl =
      'https://your-server.com/lingostream/ad-banner.html';

  static const String captureChannel = 'com.example.lingostream/capture';
  static const String translationChannel = 'com.example.lingostream/translation';

  static const Duration ocrInterval = Duration(milliseconds: 1500);
  static const Duration translationTimeout = Duration(seconds: 10);
  static const int maxTranslationChars = 500;
}
