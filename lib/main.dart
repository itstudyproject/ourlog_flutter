import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'providers/chat_provider.dart';
import 'package:ourlog/routes.dart'; // AppRoutes를 import 합니다.

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Log',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.getRoutes(), // AppRoutes.getRoutes()를 사용합니다.
      // 없는 라우트를 호출할 때 홈 화면으로 보낼 수도 있습니다.
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}
