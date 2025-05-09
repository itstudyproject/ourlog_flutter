import 'package:flutter/material.dart';

class AppTheme {
  // 앱의 기본 테마 색상 - React 스타일 반영
  static const Color primaryColor = Color(0xFF2DE1C2); // mint 색상
  static const Color secondaryColor = Color(0xFFFF9800); // orange 색상
  static const Color backgroundColor = Colors.black;
  static const Color textColor = Color(0xFFE7DED9); // 연한 베이지 색상
  static const Color accentColor = Color(0xFFFF69B4); // pink 색상
  
  // 버튼 색상
  static const Color buttonMint = Color(0xFF2DE1C2);
  static const Color buttonOrange = Color(0xFFFF9800);
  static const Color buttonBlue = Color(0xFF2196F3);
  static const Color buttonPurple = Color(0xFF9C27B0);
  
  // 앱의 라이트 테마 설정
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 50),
      headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 30),
      bodyLarge: TextStyle(color: textColor, fontSize: 18),
      bodyMedium: TextStyle(color: textColor, fontSize: 16),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: backgroundColor,
      onBackground: textColor,
      onSurface: textColor,
    ),
    cardTheme: CardTheme(
      color: Colors.black.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
  
  // 앱의 다크 테마 설정 - 기본 테마와 동일하게 설정
  static ThemeData darkTheme = lightTheme;
} 