import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';

class LingoStreamApp extends StatelessWidget {
  const LingoStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const DashboardScreen(),
    );
  }
}
