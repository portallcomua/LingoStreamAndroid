import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static const String _myMemoryApi = 'https://api.mymemory.translated.net/get';
  
  static final Map<String, String> _cache = {};
  
  static String? _targetLang;
  static String? _sourceLang;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _targetLang = prefs.getString('translation_target_lang') ?? 'uk';
    _sourceLang = prefs.getString('translation_source_lang') ?? 'en';
  }

  static String get targetLang => _targetLang ?? 'uk';
  static String get sourceLang => _sourceLang ?? 'en';

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

  static Future<String> translate(String text) async {
    if (text.trim().isEmpty) return text;
    
    final cacheKey = '$sourceLang|$targetLang|$text';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final textToTranslate = text.length > 500 ? text.substring(0, 500) : text;
      final encoded = Uri.encodeComponent(textToTranslate);
      final langPair = '${sourceLang}|$targetLang';
      
      final response = await http.get(
        Uri.parse('$_myMemoryApi?q=$encoded&langpair=$langPair'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translated = responseData?['translatedText'] as String?;
        
        if (translated != null && translated.isNotEmpty) {
          _cache[cacheKey] = translated;
          return translated;
        }
      }
      return text;
    } catch (e) {
      return text;
    }
  }

  static void clearCache() {
    _cache.clear();
  }
}
