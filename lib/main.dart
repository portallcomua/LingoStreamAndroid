import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff141414),
          elevation: 0,
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
  // Platform Channel для зв'язку з Kotlin
  static const _platform = MethodChannel('com.example.lingostream/capture');

  int _currentTab = 0;
  late String currentLanguage;
  bool isServiceRunning = false;
  String selectedMode = 'movie';
  final TextEditingController _customUrlController = TextEditingController();
  List<MediaItem> userMediaList = [];
  List<MediaItem> predefinedMedia = [];
  bool _isLoading = true;

  final Map<String, Map<String, String>> localizedData = {
    'UK': {
      'app_title': '🛸 LingoStream AI',
      'status_on': 'Перекладач: АКТИВНИЙ (OCR Екран)',
      'status_off': 'Перекладач: ВИМКНЕНО',
      'start': 'СТАРТ',
      'stop': 'СТОП',
      'mode_title': 'Режим перекладу субтитрів:',
      'mode_movie': 'Кіно & Серіали',
      'mode_pop': 'Поп-музика & Блоги',
      'mode_rock': '🎸 Рок-музика (Швидкі субтитри)',
      'media_title': '🎬 Колекції & Відео',
      'add_custom': 'Додати своє відео (URL)',
      'ad_banner': '📢 Місце для Google AdMob (BANNER_ID)',
      'no_cc_title': '⚠️ Немає субтитрів!',
      'no_cc_desc': 'Це відео не має субтитрів. Оберіть відео з позначкою "CC ✅".',
      'btn_close': 'ЗРОЗУМІЛО',
      'update_title': '🚀 Доступне оновлення!',
      'update_desc': 'Знайдено нову версію LingoStream.',
      'update_btn': 'ОНОВИТИ',
      'check_update': 'Перевірити оновлення',
      'settings': '⚙️ Налаштування',
      'language': 'Мова',
      'version': 'Версія',
      'privacy_policy': 'Політика конфіденційності',
      'delete': 'Видалити',
      'no_videos': 'Немає відео. Додайте своє!',
      'deleted': 'Видалено!',
      'overlay_title': 'Потрібен дозвіл',
      'overlay_desc': 'Для показу перекладу поверх відео потрібен дозвіл "Відображення поверх інших додатків". Надайте його в налаштуваннях.',
      'overlay_btn': 'Відкрити налаштування',
      'hint_active': '💡 Переклад відображається поверх екрана.\nВідкрийте будь-яке відео з субтитрами.',
    },
    'EN': {
      'app_title': '🛸 LingoStream AI',
      'status_on': 'Translator: ACTIVE (Screen OCR)',
      'status_off': 'Translator: OFF',
      'start': 'START',
      'stop': 'STOP',
      'mode_title': 'Subtitle Translation Mode:',
      'mode_movie': 'Movies & Series',
      'mode_pop': 'Pop Music & Vlogs',
      'mode_rock': '🎸 Rock Music (Fast Subtitles)',
      'media_title': '🎬 Collections & Video',
      'add_custom': 'Add Custom Video (URL)',
      'ad_banner': '📢 Google AdMob Placeholder (BANNER_ID)',
      'no_cc_title': '⚠️ No Subtitles!',
      'no_cc_desc': 'This video has no subtitles. Choose a video with "CC ✅" mark.',
      'btn_close': 'GOT IT',
      'update_title': '🚀 Update Available!',
      'update_desc': 'New version of LingoStream found.',
      'update_btn': 'UPDATE',
      'check_update': 'Check for Updates',
      'settings': '⚙️ Settings',
      'language': 'Language',
      'version': 'Version',
      'privacy_policy': 'Privacy Policy',
      'delete': 'Delete',
      'no_videos': 'No videos. Add yours!',
      'deleted': 'Deleted!',
      'overlay_title': 'Permission Required',
      'overlay_desc': 'To show translation over video, grant "Display over other apps" permission in settings.',
      'overlay_btn': 'Open Settings',
      'hint_active': '💡 Translation is shown over the screen.\nOpen any video with subtitles.',
    }
  };

  String t(String key) => localizedData[currentLanguage]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      predefinedMedia = MediaService.getPredefinedMedia();
      await _loadCustomVideos();
      await _loadLanguage();
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => checkForGitHubUpdates());
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null && saved != currentLanguage) {
      setState(() => currentLanguage = saved);
    }
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> _loadCustomVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? urls = prefs.getStringList('custom_videos');
    final List<String>? titles = prefs.getStringList('custom_titles');
    if (urls != null && titles != null) {
      userMediaList = List.generate(
        urls.length,
        (i) => MediaItem(
          title: titles[i],
          category: '🔗 Мої відео',
          url: urls[i],
          hasSubtitles: true,
          isCustom: true,
        ),
      );
    } else {
      userMediaList = [];
    }
  }

  Future<void> _saveCustomVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_videos', userMediaList.map((e) => e.url).toList());
    await prefs.setStringList('custom_titles', userMediaList.map((e) => e.title).toList());
  }

  // ===== PLATFORM CHANNEL: запуск/зупинка перекладача =====

  Future<void> _toggleService() async {
    if (isServiceRunning) {
      await _stopService();
    } else {
      await _startService();
    }
  }

  Future<void> _startService() async {
    try {
      final hasOverlay = await _platform.invokeMethod<bool>('hasOverlayPermission') ?? false;
      if (!hasOverlay) {
        _showOverlayPermissionDialog();
        return;
      }
      final result = await _platform.invokeMethod<bool>('startCapture') ?? false;
      if (result && mounted) {
        setState(() => isServiceRunning = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛸 Переклад запущено! Відкрийте відео.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopService() async {
    try {
      await _platform.invokeMethod('stopCapture');
      if (mounted) setState(() => isServiceRunning = false);
    } on PlatformException catch (e) {
      debugPrint('Stop error: $e');
    }
  }

  void _showOverlayPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        title: Text(t('overlay_title'), style: const TextStyle(color: Colors.cyanAccent)),
        content: Text(t('overlay_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _platform.invokeMethod('requestOverlayPermission');
            },
            child: Text(t('overlay_btn'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ===== GitHub Auto-Update =====

  Future<void> checkForGitHubUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final latestVersion = json['tag_name'].toString().replaceAll('v', '');
        if (latestVersion != packageInfo.version) {
          _showUpdateDialog(json['html_url'] ?? '');
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t('update_title')),
        content: Text(t('update_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Пізніше'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              Navigator.pop(context);
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            child: Text(t('update_btn'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdatesManually() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final latestVersion = json['tag_name'].toString().replaceAll('v', '');
        if (latestVersion != packageInfo.version) {
          _showUpdateDialog(json['html_url'] ?? '');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Версія ${packageInfo.version} актуальна')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Помилка перевірки: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  void _addCustomVideo() {
    final url = _customUrlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть коректний URL (http:// або https://)')),
      );
      return;
    }
    setState(() {
      userMediaList.add(MediaItem(
        title: 'Відео ${userMediaList.length + 1}',
        category: '🔗 Мої відео',
        url: url,
        hasSubtitles: true,
        isCustom: true,
      ));
      _customUrlController.clear();
    });
    _saveCustomVideos();
  }

  void _deleteCustomVideo(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete')),
        content: const Text('Ви впевнені?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () {
              setState(() => userMediaList.removeAt(index));
              _saveCustomVideos();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('deleted'))),
              );
            },
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoSubtitlesWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('no_cc_title'), style: const TextStyle(color: Colors.redAccent)),
        content: Text(t('no_cc_desc')),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            child: Text(t('btn_close'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('settings'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.cyanAccent),
              title: Text(t('language')),
              trailing: DropdownButton<String>(
                value: currentLanguage,
                items: const [
                  DropdownMenuItem(value: 'UK', child: Text('🇺🇦 Українська')),
                  DropdownMenuItem(value: 'EN', child: Text('🇬🇧 English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => currentLanguage = value);
                    _saveLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.cyanAccent),
              title: Text(t('check_update')),
              onTap: () {
                Navigator.pop(context);
                _checkForUpdatesManually();
              },
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) => ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: Text('${t('version')}: ${snapshot.data?.version ?? '...'}'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.grey),
              title: Text(t('privacy_policy')),
              onTap: () {
                Navigator.pop(context);
                _launchUrl(
                  'https://raw.githubusercontent.com/portallcomua/LingoStreamAndroid/main/PRIVACY_POLICY.md',
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              errorBuilder: (_, __, ___) => const Icon(Icons.translate, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 10),
            Text(t('app_title')),
          ],
        ),
        backgroundColor: const Color(0xff141414),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: _showSettings,
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [_buildMainScreen(), _buildMediaScreen()],
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
                        letterSpacing: 1.1,
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
          // Статус
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isServiceRunning ? Colors.teal.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isServiceRunning ? Colors.tealAccent : Colors.grey.shade700,
              ),
            ),
            child: Text(
              isServiceRunning ? t('status_on') : t('status_off'),
              style: TextStyle(
                fontSize: 15,
                color: isServiceRunning ? Colors.tealAccent : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (isServiceRunning) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t('hint_active'),
                style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Кнопка СТАРТ/СТОП
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _toggleService,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isServiceRunning ? Colors.redAccent : Colors.cyanAccent,
                    boxShadow: [
                      BoxShadow(
                        color: (isServiceRunning ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    isServiceRunning ? Icons.stop : Icons.play_arrow,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          Text(
            t('mode_title'),
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            title: Text(t('mode_movie')),
            value: 'movie',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v!),
          ),
          RadioListTile<String>(
            title: Text(t('mode_pop')),
            value: 'pop',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v!),
          ),
          RadioListTile<String>(
            title: Text(t('mode_rock')),
            value: 'rock',
            groupValue: selectedMode,
            onChanged: (v) => setState(() => selectedMode = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaScreen() {
    final allVideos = [...predefinedMedia, ...userMediaList];
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customUrlController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xff141414),
                    hintText: t('add_custom'),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () => _customUrlController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.cyanAccent, size: 35),
                onPressed: _addCustomVideo,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: allVideos.isEmpty
                ? Center(
                    child: Text(
                      t('no_videos'),
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: allVideos.length,
                    itemBuilder: (context, index) {
                      final item = allVideos[index];
                      return Card(
                        color: const Color(0xff141414),
                        child: ListTile(
                          leading: Icon(
                            item.category.contains('Rock')
                                ? Icons.album
                                : item.category.contains('TED')
                                    ? Icons.record_voice_over
                                    : item.category.contains('BBC')
                                        ? Icons.newspaper
                                        : item.category.contains('Мої')
                                            ? Icons.person
                                            : Icons.movie,
                            color: Colors.purpleAccent,
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "${item.category} • ${item.hasSubtitles ? 'CC ✅' : '⚠️ No CC'}",
                            style: TextStyle(
                              fontSize: 11,
                              color: item.hasSubtitles ? Colors.grey : Colors.redAccent,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isCustom)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteCustomVideo(userMediaList.indexOf(item)),
                                ),
                              Icon(
                                item.hasSubtitles ? Icons.play_circle_outline : Icons.error_outline,
                                color: item.hasSubtitles ? Colors.cyanAccent : Colors.redAccent,
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (!item.hasSubtitles) {
                              _showNoSubtitlesWarning();
                              return;
                            }
                            await _launchUrl(item.url);
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
}
