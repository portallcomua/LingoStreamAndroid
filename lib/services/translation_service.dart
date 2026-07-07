import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

enum TranslationProvider {
  googleMirror,
  myMemory,
  deepl,
  openAi,
}

class TranslationService {
  TranslationService._();

  static final Map<String, String> _cache = {};
  static TranslationProvider _provider = TranslationProvider.googleMirror;
  static String _targetLang = 'uk';
  static String _sourceLang = 'en';

  static TranslationProvider get provider => _provider;
  static String get targetLang => _targetLang;
  static String get sourceLang => _sourceLang;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _targetLang = prefs.getString('translation_target_lang') ?? 'uk';
    _sourceLang = prefs.getString('translation_source_lang') ?? 'en';
    final providerName = prefs.getString('translation_provider') ?? 'googleMirror';
    _provider = TranslationProvider.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => TranslationProvider.googleMirror,
    );
  }

  static Future<void> setTargetLang(String lang) async {
    _targetLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_target_lang', lang);
    _cache.clear();
  }

  static Future<void> setSourceLang(String lang) async {
    _sourceLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_source_lang', lang);
    _cache.clear();
  }

  static Future<void> setProvider(TranslationProvider provider) async {
    _provider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_provider', provider.name);
    _cache.clear();
  }

  static Future<String> translate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;

    final cacheKey = '${_provider.name}|$_sourceLang|$_targetLang|$trimmed';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final input = trimmed.length > AppConfig.maxTranslationChars
        ? trimmed.substring(0, AppConfig.maxTranslationChars)
        : trimmed;

    String? translated;
    switch (_provider) {
      case TranslationProvider.googleMirror:
        translated = await _translateGoogleMirror(input);
      case TranslationProvider.myMemory:
        translated = await _translateMyMemory(input);
      case TranslationProvider.deepl:
        translated = await _translateDeepL(input);
      case TranslationProvider.openAi:
        translated = await _translateOpenAi(input);
    }

    final result = (translated != null && translated.isNotEmpty) ? translated : text;
    _cache[cacheKey] = result;
    return result;
  }

  static void clearCache() => _cache.clear();

  /// Free Google Translate mirror (no API key).
  static Future<String?> _translateGoogleMirror(String text) async {
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=$_sourceLang&tl=$_targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(uri).timeout(AppConfig.translationTimeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;

      final segments = decoded[0];
      if (segments is! List) return null;

      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty && segment[0] is String) {
          buffer.write(segment[0]);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _translateMyMemory(String text) async {
    try {
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get'
        '?q=${Uri.encodeComponent(text)}&langpair=$_sourceLang|$_targetLang',
      );
      final response = await http.get(uri).timeout(AppConfig.translationTimeout);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responseData = data['responseData'] as Map<String, dynamic>?;
      return responseData?['translatedText'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Placeholder for DeepL API integration.
  /// Set your key in secure storage and uncomment the HTTP call.
  static Future<String?> _translateDeepL(String text) async {
    // const apiKey = String.fromEnvironment('DEEPL_API_KEY');
    // if (apiKey.isEmpty) return null;
    //
    // final response = await http.post(
    //   Uri.parse('https://api-free.deepl.com/v2/translate'),
    //   headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
    //   body: {'text': text, 'target_lang': _targetLang.toUpperCase()},
    // ).timeout(AppConfig.translationTimeout);
    //
    // if (response.statusCode != 200) return null;
    // final data = jsonDecode(response.body) as Map<String, dynamic>;
    // final translations = data['translations'] as List<dynamic>?;
    // return translations?.first['text'] as String?;
    return null;
  }

  /// Placeholder for OpenAI translation integration.
  static Future<String?> _translateOpenAi(String text) async {
    // const apiKey = String.fromEnvironment('OPENAI_API_KEY');
    // if (apiKey.isEmpty) return null;
    //
    // final response = await http.post(
    //   Uri.parse('https://api.openai.com/v1/chat/completions'),
    //   headers: {
    //     'Authorization': 'Bearer $apiKey',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'model': 'gpt-4o-mini',
    //     'messages': [
    //       {
    //         'role': 'system',
    //         'content': 'Translate text to $_targetLang. Return only translation.',
    //       },
    //       {'role': 'user', 'content': text},
    //     ],
    //   }),
    // ).timeout(AppConfig.translationTimeout);
    //
    // if (response.statusCode != 200) return null;
    // final data = jsonDecode(response.body) as Map<String, dynamic>;
    // final choices = data['choices'] as List<dynamic>?;
    // return choices?.first['message']?['content'] as String?;
    return null;
  }
}
