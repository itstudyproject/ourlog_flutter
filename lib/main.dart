import 'package:flutter/material.dart';
import 'package:ourlog/screens/account_edit_screen.dart';
import 'package:ourlog/screens/appinfo_screen.dart';
import 'package:ourlog/screens/bookmark_screen.dart';
import 'package:ourlog/screens/customer/customer_center_screen.dart';
import 'package:ourlog/screens/customer/privacy_policy_screen.dart';
import 'package:ourlog/screens/customer/terms_condition_screen.dart';
import 'package:ourlog/screens/my_page_screen.dart';
import 'package:ourlog/screens/profile_edit_screen.dart';
import 'package:ourlog/screens/purchase_bid_screen.dart';
import 'package:ourlog/screens/sale_screen.dart';
import 'package:provider/provider.dart';

import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/delete_user_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

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
        '/appinfo': (context) => const AppinfoScreen(),
        '/customer/termscondition': (context) => const TermsConditionScreen(),
        '/customer/privacypolicy': (context) => const PrivacyPolicyScreen(),
        '/customer/customercenter': (context) => const CustomerCenterScreen(),

        // 프로필수정 화면으로 라우팅
        '/mypage/edit': (c) {
          final auth = Provider.of<AuthProvider>(c, listen: false);
          final uid = auth.userId;
          if (uid == null) {
            // 로그인 안 된 상태면 로그인 화면으로
            return const LoginScreen();
          }
          // ❌ const 제거! 런타임 uid 넣어야 하므로
          return ProfileEditScreen(userId: uid);
        },

        // 회원정보수정
        '/mypage/account/edit': (c) {
          final auth = Provider.of<AuthProvider>(c, listen: false);
          final uid  = auth.userId;
          if (uid == null) return const LoginScreen();
          return AccountEditScreen(userId: uid);
          },

    '/mypage/purchase-bid':     (context) => const PurchaseBidScreen(),
    '/mypage/sale':             (context) => const SaleScreen(),
    '/mypage/bookmark':         (context) => const BookmarkScreen(),
    '/mypage/account/delete':   (context) => const DeleteUserScreen(),
      },
    );
  }
}
