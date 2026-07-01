import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, secondary: Colors.purpleAccent),
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
  String selectedMode = 'movie';
  String recognizedText = ""; // Сюди Google ШІ буде записувати знайдений текст
  List<MediaItem> userMediaList = MediaService.getPredefinedMedia();

  // Ініціалізація розпізнавача тексту від Google (працює локально на телефоні)
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final Map<String, Map<String, String>> localizedData = {
    'UK': {
      'status_on': 'Перекладач: СКАНУВАННЯ ЕКРАНА...',
      'status_off': 'Перекладач: ВИМКНЕНО',
      'start': 'СТАРТ',
      'stop': 'СТОП',
      'mode_title': 'Оптимізація сканування літер:',
      'mode_movie': 'Кіно & Серіали',
      'mode_pop': 'Поп-музика & Блоги',
      'mode_rock': '🎸 Рок-музика (Прискорений режим)',
      'media_title': '🎬 Колекції & Відео',
      'ad_banner': '🤖 ТУТ БУДЕ БАНЕР GOOGLE ADMOB 🤖',
      'no_cc_title': 'Увага: Немає субтитрів! ⚠️',
      'no_cc_desc': 'Це відео не має англійських субтитрів. Сканування екрана не зможе знайти текст.',
      'btn_close': 'ЗРОЗУМІЛО',
    },
    'EN': {
      'status_on': 'Translator: SCANNING SCREEN...',
      'status_off': 'Translator: OFF',
      'start': 'START',
      'stop': 'STOP',
      'mode_title': 'Text Scanning Optimization Mode:',
      'mode_movie': 'Movies & Series',
      'mode_pop': 'Pop Music & Vlogs',
      'mode_rock': '🎸 Rock Music (Fast Scan Mode)',
      'media_title': '🎬 Collections & Video',
      'ad_banner': '🤖 GOOGLE ADMOB ADS PLACEHOLDER 🤖',
      'no_cc_title': 'Warning: No Subtitles! ⚠️',
      'no_cc_desc': 'This video does not have English subtitles. Screen scanning won\'t detect text.',
      'btn_close': 'GOT IT',
    }
  };

  @override
  void dispose() {
    _textRecognizer.close(); // Обов'язково закриваємо ШІ при закритті програми
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
  }

  String t(String key) => localizedData[currentLanguage]?[key] ?? key;

  // Технічна функція активації ШІ-сканера
  void _toggleOcrService() {
    setState(() {
      isServiceRunning = !isServiceRunning;
      if (isServiceRunning) {
        recognizedText = currentLanguage == 'UK' 
            ? "ШІ запущено. Очікування субтитрів на екрані..." 
            : "AI running. Waiting for subtitles on screen...";
      } else {
        recognizedText = "";
      }
    });
  }

  void _showNoSubtitlesWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t('no_cc_title'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(t('no_cc_desc'), style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
            child: Text(t('btn_close'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛸 LingoStream AI'),
        backgroundColor: const Color(0xff141414),
        actions: [
          TextButton(
            onPressed: () => setState(() => currentLanguage = currentLanguage == 'UK' ? 'EN' : 'UK'),
            child: Text(currentLanguage, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
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
              child: Text(t('ad_banner'), style: const TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
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
          Text(isServiceRunning ? t('status_on') : t('status_off'), style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 15),
          
          // Вікно виведення результатів роботи Google ШІ сканера
          if (isServiceRunning)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent, width: 0.5)),
              child: Text(recognizedText, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontStyle: FontStyle.italic)),
            ),
            
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(35), backgroundColor: isServiceRunning ? Colors.redAccent : Colors.cyanAccent),
                onPressed: _toggleOcrService,
                child: Icon(isServiceRunning ? Icons.stop : Icons.play_arrow, size: 40, color: Colors.black),
              ),
            ),
          ),
          Text(t('mode_title'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          RadioListTile(title: Text(t('mode_movie')), value: 'movie', groupValue: selectedMode, onChanged: (v) => setState(() => selectedMode = v.toString())),
          RadioListTile(title: Text(t('mode_pop')), value: 'pop', groupValue: selectedMode, onChanged: (v) => setState(() => selectedMode = v.toString())),
          RadioListTile(title: Text(t('mode_rock')), value: 'rock', groupValue: selectedMode, onChanged: (v) => setState(() => selectedMode = v.toString())),
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
          Text(t('media_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: userMediaList.length,
              itemBuilder: (context, index) {
                final item = userMediaList[index];
                return Card(
                  color: const Color(0xff141414),
                  child: ListTile(
                    leading: Icon(item.category.contains("Rock") ? Icons.album : Icons.movie, color: Colors.purpleAccent),
                    title: Text(item.title, style: const TextStyle(fontSize: 14)),
                    subtitle: Text("${item.category} • ${item.hasSubtitles ? 'CC Available' : 'No Subtitles ⚠️'}", style: TextStyle(fontSize: 11, color: item.hasSubtitles ? Colors.grey : Colors.redAccent)),
                    trailing: Icon(item.hasSubtitles ? Icons.play_circle_outline : Icons.error_outline, color: item.hasSubtitles ? Colors.cyanAccent : Colors.redAccent),
                    onTap: () {
                      if (!item.hasSubtitles) {
                        _showNoSubtitlesWarning();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selected: ${item.title}")));
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
}
