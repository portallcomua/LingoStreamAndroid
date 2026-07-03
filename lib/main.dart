import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Widget build(BuildContext context) => MaterialApp(
    title: 'LingoStream AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xff0d0d0d),
      colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.purpleAccent),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xff141414), elevation: 0),
    ),
    home: const MainDashboard(),
  );
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const _platform = MethodChannel('com.example.lingostream/capture');
  int _tab = 0;
  String _lang = 'UK';
  bool _running = false;
  String _mode = 'movie';
  final _urlCtrl = TextEditingController();
  List<MediaItem> _custom = [];
  List<MediaItem> _predefined = [];
  bool _loading = true;

  final Map<String, Map<String, String>> _loc = {
    'UK': {
      'title': '🛸 LingoStream AI', 'on': 'Перекладач: АКТИВНИЙ', 'off': 'Перекладач: ВИМКНЕНО',
      'hint': '💡 Відкрийте відео — переклад з\'явиться знизу екрана',
      'mode': 'Режим перекладу:', 'm1': 'Кіно & Серіали', 'm2': 'Музика & Блоги', 'm3': '🎸 Рок (Швидкий)',
      'media': '🎬 Відео & Колекції', 'add': 'Додати URL відео', 'ad': '📢 Google AdMob (BANNER_ID)',
      'nocc': '⚠️ Немає субтитрів!', 'noccd': 'Відео без субтитрів. Оберіть з позначкою CC ✅',
      'ok': 'ЗРОЗУМІЛО', 'upd': '🚀 Оновлення!', 'updd': 'Нова версія LingoStream доступна',
      'updb': 'ОНОВИТИ', 'chk': 'Перевірити оновлення', 'sets': '⚙️ Налаштування',
      'lang': 'Мова', 'ver': 'Версія', 'pp': 'Конфіденційність', 'del': 'Видалити',
      'novid': 'Немає відео. Додайте своє!', 'deleted': 'Видалено!',
      'ovt': 'Потрібен дозвіл', 'ovd': 'Надайте дозвіл "Поверх інших додатків" у налаштуваннях.',
      'ovb': 'Відкрити налаштування', 'actual': 'актуальна',
    },
    'EN': {
      'title': '🛸 LingoStream AI', 'on': 'Translator: ACTIVE', 'off': 'Translator: OFF',
      'hint': '💡 Open any video — translation appears at the bottom',
      'mode': 'Translation Mode:', 'm1': 'Movies & Series', 'm2': 'Music & Vlogs', 'm3': '🎸 Rock (Fast)',
      'media': '🎬 Video & Collections', 'add': 'Add video URL', 'ad': '📢 Google AdMob (BANNER_ID)',
      'nocc': '⚠️ No Subtitles!', 'noccd': 'No subtitles. Choose video with CC ✅',
      'ok': 'GOT IT', 'upd': '🚀 Update!', 'updd': 'New LingoStream version available',
      'updb': 'UPDATE', 'chk': 'Check for Updates', 'sets': '⚙️ Settings',
      'lang': 'Language', 'ver': 'Version', 'pp': 'Privacy Policy', 'del': 'Delete',
      'novid': 'No videos. Add yours!', 'deleted': 'Deleted!',
      'ovt': 'Permission Required', 'ovd': 'Grant "Display over other apps" permission in settings.',
      'ovb': 'Open Settings', 'actual': 'up to date',
    },
  };

  String t(String k) => _loc[_lang]?[k] ?? k;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    _predefined = MediaService.getPredefinedMedia();
    final p = await SharedPreferences.getInstance();
    _lang = p.getString('lang') ?? 'UK';
    final urls = p.getStringList('cv') ?? [];
    final titles = p.getStringList('ct') ?? [];
    _custom = List.generate(urls.length, (i) => MediaItem(title: titles[i], category: '🔗 Мої відео', url: urls[i], isCustom: true));
    if (mounted) setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _saveLang(String l) async { final p = await SharedPreferences.getInstance(); await p.setString('lang', l); }
  Future<void> _saveCustom() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('cv', _custom.map((e) => e.url).toList());
    await p.setStringList('ct', _custom.map((e) => e.title).toList());
  }

  Future<void> _toggleService() async {
    if (_running) {
      try { await _platform.invokeMethod('stopCapture'); if (mounted) setState(() => _running = false); }
      catch (e) { debugPrint('stop: $e'); }
    } else {
      try {
        final hasOverlay = await _platform.invokeMethod<bool>('hasOverlayPermission') ?? false;
        if (!hasOverlay) { _showOverlayDialog(); return; }
        final ok = await _platform.invokeMethod<bool>('startCapture') ?? false;
        if (ok && mounted) {
          setState(() => _running = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🛸 Переклад запущено!'), backgroundColor: Colors.teal));
        }
      } on PlatformException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: ${e.message}'), backgroundColor: Colors.red));
      }
    }
  }

  void _showOverlayDialog() => showDialog(context: context, builder: (c) => AlertDialog(
    backgroundColor: const Color(0xff1a1a1a),
    title: Text(t('ovt'), style: const TextStyle(color: Colors.cyanAccent)),
    content: Text(t('ovd')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Скасувати')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () async { Navigator.pop(c); await _platform.invokeMethod('requestOverlayPermission'); },
        child: Text(t('ovb'), style: const TextStyle(color: Colors.black))),
    ],
  ));

  Future<void> _checkUpdate({bool manual = false}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final r = await http.get(Uri.parse('https://api.github.com/repos/portallcomua/LingoStreamAndroid/releases/latest'));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        final latest = j['tag_name'].toString().replaceAll('v', '');
        if (latest != info.version) {
          _showUpdateDialog(j['html_url'] ?? '');
        } else if (manual && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${info.version} ${t('actual')}')));
        }
      }
    } catch (e) { debugPrint('update: $e'); }
  }

  void _showUpdateDialog(String url) => showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
    title: Text(t('upd')), content: Text(t('updd')),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Пізніше')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
        onPressed: () async { Navigator.pop(c); if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); },
        child: Text(t('updb'), style: const TextStyle(color: Colors.black))),
    ],
  ));

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _addVideo() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) return;
    setState(() { _custom.add(MediaItem(title: 'Відео ${_custom.length + 1}', category: '🔗 Мої відео', url: url, isCustom: true)); _urlCtrl.clear(); });
    _saveCustom();
  }

  void _deleteVideo(int i) => showDialog(context: context, builder: (c) => AlertDialog(
    title: Text(t('del')), content: const Text('Ви впевнені?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Ні')),
      TextButton(onPressed: () { setState(() => _custom.removeAt(i)); _saveCustom(); Navigator.pop(c);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('deleted')))); },
        child: const Text('Так', style: TextStyle(color: Colors.red))),
    ],
  ));

  void _showSettings() => showModalBottomSheet(context: context, backgroundColor: const Color(0xff1a1a1a),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(t('sets'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
      const Divider(color: Colors.grey),
      ListTile(leading: const Icon(Icons.language, color: Colors.cyanAccent), title: Text(t('lang')),
        trailing: DropdownButton<String>(value: _lang, items: const [
          DropdownMenuItem(value: 'UK', child: Text('🇺🇦 Українська')),
          DropdownMenuItem(value: 'EN', child: Text('🇬🇧 English')),
        ], onChanged: (v) { if (v != null) { setState(() => _lang = v); _saveLang(v); Navigator.pop(c); } })),
      ListTile(leading: const Icon(Icons.update, color: Colors.cyanAccent), title: Text(t('chk')),
        onTap: () { Navigator.pop(c); _checkUpdate(manual: true); }),
      FutureBuilder<PackageInfo>(future: PackageInfo.fromPlatform(),
        builder: (_, s) => ListTile(leading: const Icon(Icons.info, color: Colors.grey), title: Text('${t('ver')}: ${s.data?.version ?? '...'}')),
      ),
      ListTile(leading: const Icon(Icons.privacy_tip, color: Colors.grey), title: Text(t('pp')),
        onTap: () { Navigator.pop(c); _launch('https://github.com/portallcomua/LingoStreamAndroid/blob/main/PRIVACY_POLICY.md'); }),
      const SizedBox(height: 20),
    ])));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Row(children: [
      Image.asset('assets/logo.png', height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.translate, color: Colors.cyanAccent)),
      const SizedBox(width: 8), Text(t('title')),
    ]), actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.cyanAccent), onPressed: _showSettings)]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
      Expanded(child: IndexedStack(index: _tab, children: [_mainScreen(), _mediaScreen()])),
      Container(height: 48, color: Colors.purple.withOpacity(0.15),
        child: Center(child: Text(t('ad'), style: const TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold)))),
    ]),
    bottomNavigationBar: BottomNavigationBar(currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
      selectedItemColor: Colors.cyanAccent, backgroundColor: const Color(0xff141414),
      items: const [BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '⚡'), BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '🎬')]),
  );

  Widget _mainScreen() => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _running ? Colors.teal.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: _running ? Colors.tealAccent : Colors.grey.shade700)),
      child: Text(_running ? t('on') : t('off'), style: TextStyle(fontSize: 15, color: _running ? Colors.tealAccent : Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
    if (_running) ...[const SizedBox(height: 10), Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(t('hint'), style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 13), textAlign: TextAlign.center))],
    Expanded(child: Center(child: GestureDetector(onTap: _toggleService, child: Container(width: 130, height: 130,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _running ? Colors.redAccent : Colors.cyanAccent,
        boxShadow: [BoxShadow(color: (_running ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.4), blurRadius: 25, spreadRadius: 5)]),
      child: Icon(_running ? Icons.stop : Icons.play_arrow, size: 60, color: Colors.black))))),
    Text(t('mode'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    RadioListTile(title: Text(t('m1')), value: 'movie', groupValue: _mode, onChanged: (v) => setState(() => _mode = v!)),
    RadioListTile(title: Text(t('m2')), value: 'pop', groupValue: _mode, onChanged: (v) => setState(() => _mode = v!)),
    RadioListTile(title: Text(t('m3')), value: 'rock', groupValue: _mode, onChanged: (v) => setState(() => _mode = v!)),
  ]));

  Widget _mediaScreen() {
    final all = [..._predefined, ..._custom];
    return Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('media'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextField(controller: _urlCtrl, decoration: InputDecoration(filled: true, fillColor: const Color(0xff141414),
          hintText: t('add'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          suffixIcon: IconButton(icon: const Icon(Icons.clear, size: 18, color: Colors.grey), onPressed: _urlCtrl.clear)))),
        IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyanAccent, size: 35), onPressed: _addVideo),
      ]),
      const SizedBox(height: 10),
      Expanded(child: all.isEmpty ? Center(child: Text(t('novid'), style: const TextStyle(color: Colors.grey)))
        : ListView.builder(itemCount: all.length, itemBuilder: (_, i) {
          final item = all[i];
          return Card(color: const Color(0xff141414), child: ListTile(
            leading: Icon(item.category.contains('Rock') || item.category.contains('🎸') ? Icons.album : item.category.contains('TED') ? Icons.record_voice_over : item.isCustom ? Icons.person : Icons.movie, color: Colors.purpleAccent),
            title: Text(item.title, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.category} • ${item.hasSubtitles ? 'CC ✅' : '⚠️ No CC'}', style: TextStyle(fontSize: 11, color: item.hasSubtitles ? Colors.grey : Colors.redAccent)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (item.isCustom) IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteVideo(_custom.indexOf(item))),
              Icon(item.hasSubtitles ? Icons.play_circle_outline : Icons.error_outline, color: item.hasSubtitles ? Colors.cyanAccent : Colors.redAccent),
            ]),
            onTap: () { if (!item.hasSubtitles) { showDialog(context: context, builder: (c) => AlertDialog(title: Text(t('nocc'), style: const TextStyle(color: Colors.redAccent)), content: Text(t('noccd')), actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(c), child: Text(t('ok')))])); return; } _launch(item.url); },
          ));
        })),
    ]));
  }
}
