import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'media_service.dart';

void main() => runApp(const LingoStreamApp());

class LingoStreamApp extends StatelessWidget {
  const LingoStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String systemLocale = PlatformDispatcher.instance.locale.languageCode;
    return MaterialApp(
      title: 'LingoStream AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff0d0d0d),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      home: MainDashboard(initialLanguage: systemLocale == 'uk' ? 'UK' : 'EN'),
    );
  }
}

class MainDashboard extends StatefulWidget {
  final String initialLanguage;
  const MainDashboard({super.key, required this.initialLanguage});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentTab = 0;
  late String currentLanguage;
  bool isServiceRunning = false;
  bool isPremium = false;
  String selectedMode = 'movie';
  String recognizedText = "";
  String translatedText = "";
  bool isTranslating = false;

  MediaItem? activePlayingVideo;

  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customIdController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  String selectedCategory = "🎬 Movies & Series";

  // Для ML Kit
  late TextRecognizer _textRecognizer;
  late GoogleTranslator _translator;

  List<MediaItem> userMediaList = MediaService.getPredefinedMedia();

  final Map<String, Map<String, String>> localizedData = {
    'UK': {
      'status_on': 'Перекладач: СКАНУВАННЯ ЕКРАНА (ШІ Google ML Kit)...',
      'status_off': 'Перекладач: ВИМКНЕНО',
      'start': 'СТАРТ',
      'stop': 'СТОП',
      'mode_title': 'Оптимізація роботи ШІ перекладача:',
      'mode_movie': 'Кіно & Серіали',
      'mode_pop': 'Поп-музика & Блоги',
      'mode_rock': '🎸 Рок-музика (Прискорений режим)',
      'media_title': '🎬 Вбудована Медіатека',
      'add_title': 'Додати нове відео:',
      'hint_title': 'Назва фільму або пісні',
      'hint_id': 'YouTube Video ID (літери після =)',
      'btn_add': 'ДОДАТИ В КОЛЕКЦІЮ',
      'ad_banner': '🤖 ТУТ БУДЕ БАНЕР GOOGLE ADMOB (BANNER_ID) 🤖',
      'no_cc_title': 'Потрібен Premium доступ! 💎',
      'no_cc_desc': 'Це відео не має англійських субтитрів. Переклад чистого голосу (ШІ-аудіо Whisper) доступний лише у Premium підписці! Активуйте її у вкладці 💎.',
      'btn_close': 'ЗРОЗУМІЛО',
      'update_title': 'Доступне автооновлення! 🚀',
      'update_desc': 'Знайдено нову версію LingoStream. Оновіть додаток в один клік без видалення програми.',
      'update_btn': 'ОНОВИТИ ЗАРАЗ',
      'premium_title': 'Активація Premium',
      'premium_desc': 'Введіть ліцензійний ключ для розблокування перекладу голосу (без субтитрів) та Особистого словника.',
      'btn_activate': 'АКТИВУВАТИ ПРЕМІУМ',
      'btn_buy_payhip': '🛒 КУПИТИ PREMIUM КЛЮЧ',
      'success_msg': 'Premium успішно активовано! 🎸🛸',
      'error_msg': 'Невірний або заблокований ключ!',
      'player_title': '📺 Вбудований Медіаплеєр LingoStream',
      'translated_label': '📝 Переклад:',
      'recognized_label': '🔍 Розпізнано:',
    },
    'EN': {
      'status_on': 'Translator: SCANNING SCREEN (Google ML Kit)...',
      'status_off': 'Translator: OFF',
      'start': 'START',
      'stop': 'STOP',
      'mode_title': 'AI Translator Optimization Mode:',
      'mode_movie': 'Movies & Series',
      'mode_pop': 'Pop Music & Vlogs',
      'mode_rock': '🎸 Rock Music (Fast Scan Mode)',
      'media_title': '🎬 Built-In Media Library',
      'add_title': 'Add New Video:',
      'hint_title': 'Movie or Song Title',
      'hint_id': 'YouTube Video ID (letters after =)',
      'btn_add': 'ADD TO COLLECTION',
      'ad_banner': '🤖 GOOGLE ADMOB ADS PLACEHOLDER (BANNER_ID) 🤖',
      'no_cc_title': 'Premium Access Required! 💎',
      'no_cc_desc': 'This video has no subtitles. Pure voice translation (Whisper AI) is a Premium feature! Please activate it in 💎 tab.',
      'btn_close': 'GOT IT',
      'update_title': 'Auto-Update Available! 🚀',
      'update_desc': 'A new version of LingoStream found. Update instantly without deleting the app.',
      'update_btn': 'UPDATE NOW',
      'premium_title': 'Activate Premium',
      'premium_desc': 'Enter the license key to unlock voice translation and Personal Dictionary.',
      'btn_activate': 'ACTIVATE PREMIUM',
      'btn_buy_payhip': '🛒 BUY PREMIUM KEY',
      'success_msg': 'Premium activated successfully! 🎸🛸',
      'error_msg': 'Invalid or blocked license key!',
      'player_title': '📺 LingoStream Internal Player',
      'translated_label': '📝 Translation:',
      'recognized_label': '🔍 Recognized:',
    }
  };

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    _initMLKit();
    WidgetsBinding.instance.addPostFrameCallback((_) => checkForGitHubUpdates());
  }

  // ========== ІНІЦІАЛІЗАЦІЯ ML KIT ==========
  void _initMLKit() {
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
    _translator = GoogleTranslator(
      sourceLanguage: 'en',
      targetLanguage: currentLanguage == 'UK' ? 'uk' : 'en',
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _translator.close();
    super.dispose();
  }

  String t(String key) => localizedData[currentLanguage]?[key] ?? key;

  // ========== ПЕРЕВІРКА ОНОВЛЕНЬ (АВТООНОВЛЕННЯ) ==========
  Future<void> checkForGitHubUpdates() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String base = "https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest";

      final response = await http.get(Uri.parse(base));
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        String latestVersion = json['tag_name'].toString().replaceAll('v', '');
        if (latestVersion != currentVersion) {
          _showUpdateDialog();
        }
      }
    } catch (e) {
      print("GitHub Auto-Update Error: $e");
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t('update_title')),
        content: Text(t('update_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () {
              Navigator.pop(context);
              // Відкриваємо GitHub Releases
              _launchUrl("https://github.com/portallcomua/LingoStreamAndroid/releases/latest");
            },
            child: Text(
              t('update_btn'),
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) {
    // Тут можна додати url_launcher або просто показати повідомлення
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Відкрийте: $url'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ========== ФУНКЦІЯ РОЗПІЗНАВАННЯ ТА ПЕРЕКЛАДУ ==========
  Future<void> _recognizeAndTranslate() async {
    if (!isServiceRunning) return;

    setState(() {
      isTranslating = true;
      recognizedText = "Розпізнавання тексту...";
      translatedText = "Переклад...";
    });

    try {
      // Тут має бути реальне розпізнавання з екрана
      // Для демонстрації використовуємо тестовий текст
      String mockText = "Hello, this is a test message from LingoStream AI!";
      
      setState(() {
        recognizedText = mockText;
      });

      // Переклад
      final result = await _translator.translate(mockText);
      
      setState(() {
        translatedText = result;
        isTranslating = false;
      });
    } catch (e) {
      setState(() {
        recognizedText = "Помилка розпізнавання: $e";
        translatedText = "Помилка перекладу";
        isTranslating = false;
      });
    }
  }

  void _addCustomVideo() {
    String title = _customTitleController.text.trim();
    String id = _customIdController.text.trim();
    if (title.isNotEmpty && id.isNotEmpty) {
      setState(() {
        userMediaList.add(MediaItem(
          title: title,
          category: selectedCategory,
          videoId: id,
          hasSubtitles: true,
        ));
        _customTitleController.clear();
        _customIdController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛸 LingoStream AI'),
        backgroundColor: const Color(0xff141414),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              currentLanguage = currentLanguage == 'UK' ? 'EN' : 'UK';
              // Оновлюємо мову перекладу
              _translator = GoogleTranslator(
                sourceLanguage: 'en',
                targetLanguage: currentLanguage == 'UK' ? 'uk' : 'en',
              );
            }),
            child: Text(
              currentLanguage,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.stars, color: isPremium ? Colors.amber : Colors.grey),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildMainScreen(),
                _buildMediaScreen(),
                _buildPremiumScreen(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 50,
            color: Colors.purple.withOpacity(0.15),
            child: Center(
              child: Text(
                t('ad_banner'),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: Colors.cyanAccent,
        backgroundColor: const Color(0xff141414),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '⚡'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '🎬'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: '💎'),
        ],
      ),
    );
  }

  Widget _buildMainScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isServiceRunning ? t('status_on') : t('status_off'),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),

          // Вбудований плеєр
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xff141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: activePlayingVideo == null
                ? const Center(
                    child: Text(
                      "Оберіть трек або фільм у вкладці 🎬",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        size: 45,
                        color: Colors.purpleAccent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activePlayingVideo!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "▶️ ID: ${activePlayingVideo!.videoId}",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 15),

          // Розпізнаний текст
          if (isServiceRunning)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('recognized_label'),
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recognizedText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t('translated_label'),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isTranslating ? "Перекладаю..." : translatedText,
                    style: TextStyle(
                      color: isTranslating ? Colors.grey : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Головна кнопка
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(30),
                  backgroundColor: isServiceRunning
                      ? Colors.redAccent
                      : Colors.cyanAccent,
                ),
                onPressed: () {
                  setState(() {
                    isServiceRunning = !isServiceRunning;
                    if (isServiceRunning) {
                      recognizedText = "Розпізнавання запущено...";
                      translatedText = "Очікуємо переклад...";
                      // Запускаємо розпізнавання та переклад
                      _recognizeAndTranslate();
                    } else {
                      recognizedText = "";
                      translatedText = "";
                    }
                  });
                },
                child: Icon(
                  isServiceRunning ? Icons.stop : Icons.play_arrow,
                  size: 35,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          Text(
            t('mode_title'),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          RadioListTile(
            title: Text(t('mode_movie')),
            value: 'movie',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v.toString()),
          ),
          RadioListTile(
            title: Text(t('mode_pop')),
            value: 'pop',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v.toString()),
          ),
          RadioListTile(
            title: Text(t('mode_rock')),
            value: 'rock',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaScreen() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('media_title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            title: Text(
              t('add_title'),
              style: const TextStyle(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            collapsedBackgroundColor: const Color(0xff141414),
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _customTitleController,
                      decoration: InputDecoration(hintText: t('hint_title')),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customIdController,
                      decoration: InputDecoration(hintText: t('hint_id')),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xff141414),
                      items: [
                        "🎬 Movies & Series",
                        "🎸 Rock Music",
                        "🎵 Pop Music & Vlogs"
                      ].map((String v) => DropdownMenuItem(
                        value: v,
                        child: Text(v),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addCustomVideo,
                      child: Text(t('btn_add')),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: userMediaList.length,
              itemBuilder: (context, index) {
                final item = userMediaList[index];
                return Card(
                  color: const Color(0xff141414),
                  child: ListTile(
                    leading: Icon(
                      item.category.contains("Rock") ? Icons.album : Icons.movie,
                      color: Colors.purpleAccent,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      "${item.category} • ${item.hasSubtitles ? 'CC Available' : 'No Subtitles ⚠️'}",
                      style: TextStyle(
                        fontSize: 11,
                        color: item.hasSubtitles ? Colors.grey : Colors.redAccent,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () => setState(() => userMediaList.removeAt(index)),
                    ),
                    onTap: () {
                      if (!item.hasSubtitles && !isPremium) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(t('no_cc_title')),
                            content: Text(t('no_cc_desc')),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(t('btn_close')),
                              ),
                            ],
                          ),
                        );
                      } else {
                        setState(() {
                          activePlayingVideo = item;
                          _currentTab = 0;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('premium_title'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t('premium_desc'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase page will open'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text(
              t('btn_buy_payhip'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _licenseController,
            enabled: !isPremium,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xff141414),
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.green : Colors.purpleAccent,
            ),
            onPressed: () {
              setState(() {
                isPremium = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t('success_msg')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              isPremium ? t('success_msg').toUpperCase() : t('btn_activate'),
            ),
          ),
        ],
      ),
    );
  }
}
