import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/media_item.dart';
import '../services/camera_capture_service.dart';
import '../services/capture_service.dart';
import '../services/media_service.dart';
import '../services/ocr_service.dart';
import '../services/permission_service.dart';
import '../services/translation_service.dart';
import '../services/update_service.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/subtitle_bubble.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  String _lang = 'UK';
  bool _running = false;
  String _mode = 'movie';
  CaptureMode _captureMode = CaptureMode.screenOverlay;
  TranslationProvider _provider = TranslationProvider.googleMirror;

  String _originalSubtitle = '';
  String _translatedSubtitle = '';

  final _urlCtrl = TextEditingController();
  List<MediaItem> _custom = [];
  List<MediaItem> _predefined = [];
  bool _loading = true;

  late final OcrService _ocrService;
  late final CameraCaptureService _cameraService;

  String t(String key) => AppLocalizations.t(_lang, key);

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _cameraService = CameraCaptureService(ocrService: _ocrService);
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _cameraService.stop();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _predefined = MediaService.getPredefinedMedia();
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'UK';
    _provider = TranslationService.provider;

    final urls = prefs.getStringList('cv') ?? [];
    final titles = prefs.getStringList('ct') ?? [];
    _custom = List.generate(
      urls.length,
      (index) => MediaItem(
        title: titles[index],
        category: '🔗 Мої відео',
        url: urls[index],
        isCustom: true,
      ),
    );

    if (mounted) setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _saveLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }

  Future<void> _saveCustom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cv', _custom.map((item) => item.url).toList());
    await prefs.setStringList('ct', _custom.map((item) => item.title).toList());
  }

  Future<void> _toggleService() async {
    if (_running) {
      await _stopService();
      return;
    }
    await _startService();
  }

  Future<void> _startService() async {
    if (_captureMode == CaptureMode.screenOverlay) {
      final hasOverlay = await CaptureService.hasOverlayPermission();
      if (!hasOverlay) {
        _showOverlayDialog();
        return;
      }

      final started = await CaptureService.startScreenCapture(
        sourceLang: TranslationService.sourceLang,
        targetLang: TranslationService.targetLang,
        mode: _mode,
      );

      if (!mounted) return;
      if (started) {
        setState(() => _running = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('started')), backgroundColor: Colors.teal),
        );
      }
      return;
    }

    final hasCamera = await PermissionService.ensureCamera();
    if (!hasCamera) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('camd')), backgroundColor: Colors.orange),
      );
      return;
    }

    final started = await _cameraService.start(
      onSubtitle: (original, translated) {
        if (!mounted) return;
        setState(() {
          _originalSubtitle = original;
          _translatedSubtitle = translated;
          _running = true;
        });
      },
    );

    if (!mounted) return;
    if (started) {
      setState(() => _running = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('started')), backgroundColor: Colors.teal),
      );
    }
  }

  Future<void> _stopService() async {
    if (_captureMode == CaptureMode.screenOverlay) {
      await CaptureService.stopScreenCapture();
    } else {
      await _cameraService.stop();
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _originalSubtitle = '';
      _translatedSubtitle = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('stopped'))),
    );
  }

  void _showOverlayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        title: Text(t('ovt'), style: const TextStyle(color: Colors.cyanAccent)),
        content: Text(t('ovd')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              Navigator.pop(context);
              await CaptureService.requestOverlayPermission();
            },
            child: Text(t('ovb'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate({bool manual = false}) async {
    final result = await UpdateService.check();
    if (!mounted) return;

    if (result.hasUpdate) {
      _showUpdateDialog(result.releaseUrl ?? '');
      return;
    }

    if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${result.fullCurrentVersion} ${t('actual')}')),
      );
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t('upd')),
        content: Text(t('updd')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Пізніше')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            onPressed: () async {
              Navigator.pop(context);
              await UpdateService.openReleaseUrl(url);
            },
            child: Text(t('updb'), style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _addVideo() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return;
    }

    setState(() {
      _custom.add(
        MediaItem(
          title: 'Відео ${_custom.length + 1}',
          category: '🔗 Мої відео',
          url: url,
          isCustom: true,
        ),
      );
      _urlCtrl.clear();
    });
    _saveCustom();
  }

  void _deleteVideo(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('del')),
        content: const Text('Ви впевнені?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ні')),
          TextButton(
            onPressed: () {
              setState(() => _custom.removeAt(index));
              _saveCustom();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('deleted'))));
            },
            child: const Text('Так', style: TextStyle(color: Colors.red)),
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
          children: [
            Text(
              t('sets'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.cyanAccent),
              title: Text(t('lang')),
              trailing: DropdownButton<String>(
                value: _lang,
                items: const [
                  DropdownMenuItem(value: 'UK', child: Text('🇺🇦 Українська')),
                  DropdownMenuItem(value: 'EN', child: Text('🇬🇧 English')),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _lang = value);
                  await _saveLang(value);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.translate, color: Colors.cyanAccent),
              title: Text(t('provider')),
              trailing: DropdownButton<TranslationProvider>(
                value: _provider,
                items: const [
                  DropdownMenuItem(
                    value: TranslationProvider.googleMirror,
                    child: Text('Google Mirror'),
                  ),
                  DropdownMenuItem(
                    value: TranslationProvider.myMemory,
                    child: Text('MyMemory'),
                  ),
                  DropdownMenuItem(
                    value: TranslationProvider.deepl,
                    child: Text('DeepL (stub)'),
                  ),
                  DropdownMenuItem(
                    value: TranslationProvider.openAi,
                    child: Text('OpenAI (stub)'),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  await TranslationService.setProvider(value);
                  setState(() => _provider = value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.cyanAccent),
              title: Text(t('chk')),
              onTap: () {
                Navigator.pop(context);
                _checkUpdate(manual: true);
              },
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snapshot) => ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: Text('${t('ver')}: ${snapshot.data?.version ?? '...'}'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.grey),
              title: Text(t('pp')),
              onTap: () {
                Navigator.pop(context);
                _launch(
                  'https://github.com/portallcomua/LingoStreamAndroid/blob/main/PRIVACY_POLICY.md',
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
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.translate, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 8),
            Text(t('title')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      _mainScreen(),
                      _mediaScreen(),
                    ],
                  ),
                ),
                const AdBannerWidget(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        selectedItemColor: Colors.cyanAccent,
        backgroundColor: const Color(0xff141414),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '⚡'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '🎬'),
        ],
      ),
    );
  }

  Widget _mainScreen() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _running ? Colors.teal.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _running ? Colors.tealAccent : Colors.grey.shade700),
                ),
                child: Text(
                  _running ? t('on') : t('off'),
                  style: TextStyle(
                    fontSize: 15,
                    color: _running ? Colors.tealAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_running) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t('hint'),
                    style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(t('captureMode'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              SegmentedButton<CaptureMode>(
                segments: [
                  ButtonSegment(value: CaptureMode.screenOverlay, label: Text(t('screenMode'))),
                  ButtonSegment(value: CaptureMode.camera, label: Text(t('cameraMode'))),
                ],
                selected: {_captureMode},
                onSelectionChanged: (values) async {
                  if (_running) await _stopService();
                  setState(() => _captureMode = values.first);
                },
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _toggleService,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _running ? Colors.redAccent : Colors.cyanAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (_running ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _running ? Icons.stop : Icons.play_arrow,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Text(t('mode'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              RadioListTile(
                title: Text(t('m1')),
                value: 'movie',
                groupValue: _mode,
                onChanged: (value) => setState(() => _mode = value!),
              ),
              RadioListTile(
                title: Text(t('m2')),
                value: 'pop',
                groupValue: _mode,
                onChanged: (value) => setState(() => _mode = value!),
              ),
              RadioListTile(
                title: Text(t('m3')),
                value: 'rock',
                groupValue: _mode,
                onChanged: (value) => setState(() => _mode = value!),
              ),
            ],
          ),
        ),
        if (_captureMode == CaptureMode.camera && _running)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SubtitleBubble(
              original: _originalSubtitle,
              translated: _translatedSubtitle.isEmpty ? t('waiting') : _translatedSubtitle,
            ),
          ),
      ],
    );
  }

  Widget _mediaScreen() {
    final all = [..._predefined, ..._custom];
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('media'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xff141414),
                    hintText: t('add'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: _urlCtrl.clear,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.cyanAccent, size: 35),
                onPressed: _addVideo,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: all.isEmpty
                ? Center(child: Text(t('novid'), style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: all.length,
                    itemBuilder: (_, index) {
                      final item = all[index];
                      return Card(
                        color: const Color(0xff141414),
                        child: ListTile(
                          leading: Icon(
                            item.category.contains('Rock') || item.category.contains('🎸')
                                ? Icons.album
                                : item.category.contains('TED')
                                    ? Icons.record_voice_over
                                    : item.isCustom
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
                            '${item.category} • ${item.hasSubtitles ? 'CC ✅' : '⚠️ No CC'}',
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
                                  onPressed: () => _deleteVideo(_custom.indexOf(item)),
                                ),
                              Icon(
                                item.hasSubtitles ? Icons.play_circle_outline : Icons.error_outline,
                                color: item.hasSubtitles ? Colors.cyanAccent : Colors.redAccent,
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!item.hasSubtitles) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    t('nocc'),
                                    style: const TextStyle(color: Colors.redAccent),
                                  ),
                                  content: Text(t('noccd')),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(t('ok')),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            _launch(item.url);
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
