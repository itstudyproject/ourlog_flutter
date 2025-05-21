import 'package:flutter/material.dart';
import 'package:ourlog/screens/my_page_screen.dart';
// import 'package:ourlog/screens/purchase_bid_screen.dart';
// import 'package:ourlog/screens/sale_screen.dart';
// import 'package:ourlog/screens/bookmark_screen.dart';
import 'package:ourlog/screens/profile_edit_screen.dart';
import 'package:ourlog/screens/account_edit_screen.dart';
import 'package:provider/provider.dart';
import 'constants/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/delete_user_screen.dart';
import 'providers/auth_provider.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      themeMode: ThemeMode.system, // 시스템 테마 설정 따르기
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/delete': (context) => const DeleteUserScreen(),
        '/mypage': (context) => const MyPageScreen(),

    // 마이페이지 및 서브 페이지들
    // '/mypage/purchase-bid':     (context) => const PurchaseBidScreen(),
    // '/mypage/sale':             (context) => const SaleScreen(),
    // '/mypage/bookmark':         (context) => const BookmarkScreen(),
    // '/mypage/edit':             (context) => const ProfileEditScreen(userId: /*유저ID*/)),
    // '/mypage/account/edit':     (context) => const AccountEditScreen(),
    '/mypage/account/delete':   (context) => const DeleteUserScreen(),
      },
    );
  }
}
