import 'package:flutter/material.dart';
import 'dart:ui';

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
  bool isPremium = false;
  int freeMinutesLeft = 30;
  String selectedMode = 'movie';
  final TextEditingController _licenseController = TextEditingController();

  final Map<String, Map<String, String>> localizedData = {
    'UK': {
      'status_on': 'Перекладач: ПРАЦЮЄ',
      'status_off': 'Перекладач: ВИМКНЕНО',
      'start': 'СТАРТ',
      'stop': 'СТОП',
      'mode_title': 'Оберіть regime ШІ:',
      'mode_movie': 'Кіно & Серіали',
      'mode_pop': 'Поп-музика',
      'mode_rock': 'Рок (Важкий вокал)',
      'free_limit': 'Залишилося ШІ-голосу:',
      'min': 'хв',
      'premium_title': 'Активація Premium (Payhip)',
      'premium_desc': 'Введіть ліцензійний ключ для розблокування.',
      'btn_activate': 'АКТИВУВАТИ ПРЕМІУМ',
      'dict_title': 'Мій Словник LingoStream',
    },
    'EN': {
      'status_on': 'Translator: RUNNING',
      'status_off': 'Translator: OFF',
      'start': 'START',
      'stop': 'STOP',
      'mode_title': 'Select AI Mode:',
      'mode_movie': 'Movies & Series',
      'mode_pop': 'Pop Music',
      'mode_rock': 'Rock (Heavy Vocals)',
      'free_limit': 'Free AI Voice left:',
      'min': 'min',
      'premium_title': 'Activate Premium (Payhip)',
      'premium_desc': 'Enter license key to unlock features.',
      'btn_activate': 'ACTIVATE PREMIUM',
      'dict_title': 'My LingoStream Dictionary',
    }
  };

  @override
  void initState() {
    super.initState();
    currentLanguage = widget.initialLanguage;
  }

  String t(String key) => localizedData[currentLanguage]?[key] ?? key;

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
          Icon(Icons.stars, color: isPremium ? Colors.amber : Colors.grey),
          const SizedBox(width: 15),
        ],
      ),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildMainScreen(),
          _buildDictionaryView(t('dict_title')),
          _buildPremiumView(t('premium_title'), t('premium_desc'), t('btn_activate')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xff141414),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: '⚡'),
          BottomNavigationBarItem(icon: Icon(Icons.g_translate), label: '📚'),
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
          Text(isServiceRunning ? t('status_on') : t('status_off'), style: const TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 25),
          if (!isPremium) Text('${t('free_limit')} $freeMinutesLeft ${t('min')}', style: const TextStyle(color: Colors.purpleAccent)),
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(), 
                  padding: const EdgeInsets.all(35),
                  backgroundColor: isServiceRunning ? Colors.redAccent : Colors.cyanAccent,
                ),
                onPressed: () => setState(() => isServiceRunning = !isServiceRunning),
                child: Icon(isServiceRunning ? Icons.stop : Icons.play_arrow, size: 40, color: Colors.black),
              ),
            ),
          ),
          Text(t('mode_title'), style: const TextStyle(color: Colors.grey)),
          RadioListTile(
            title: Text(t('mode_movie'), style: const TextStyle(color: Colors.white)), 
            value: 'movie', 
            groupValue: selectedMode, 
            onChanged: (v) => setState(() => selectedMode = v.toString())
          ),
          RadioListTile(
            title: Text(t('mode_pop'), style: const TextStyle(color: Colors.white)), 
            value: 'pop', 
            groupValue: selectedMode, 
            onChanged: (v) => setState(() => selectedMode = v.toString())
          ),
          RadioListTile(
            title: Text(t('mode_rock'), style: const TextStyle(color: Colors.white)), 
            value: 'rock', 
            groupValue: selectedMode, 
            onChanged: (v) {
              if (!isPremium) { 
                setState(() => _currentTab = 2); 
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(currentLanguage == 'UK' ? 'Режим "Рок" доступний лише у Premium підписці!' : 'Rock mode is only available in Premium subscription!')),
                );
              } else { 
                setState(() => selectedMode = v.toString()); 
              }
            }
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryView(String title) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          const Expanded(child: Center(child: Text('Тут будуть збережені слова', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }

  Widget _buildPremiumView(String title, String desc, String btn) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 15),
          Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          TextField(
            controller: _licenseController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true, 
              fillColor: const Color(0xff141414), 
              hintText: 'XXXX-XXXX',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (_licenseController.text.trim().isNotEmpty) {
                setState(() {
                  isPremium = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(currentLanguage == 'UK' ? 'Premium активовано! 🎸🛸' : 'Premium activated! 🎸🛸'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text(btn, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
