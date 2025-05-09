import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// 앱의 모든 경로를 관리하는 클래스
class AppRoutes {
  static const String home = '/';
  // 여기에 추가 경로 정의

  // 네임드 라우트 설정
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      // 여기에 추가 경로 추가
    };
  }
} 