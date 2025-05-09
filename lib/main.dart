import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Log',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 시스템 테마 설정 따르기
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
    );
  }
}
