import 'package:flutter/material.dart';
import 'package:ourlog/screens/account_edit_screen.dart';
import 'package:ourlog/screens/art/art_register_screen.dart';
import 'package:ourlog/screens/art/artlist_screen.dart';
import 'package:ourlog/screens/bookmark_screen.dart';

import 'package:ourlog/screens/customer/answer_screen.dart';
import 'package:ourlog/screens/post/community_post_detail_screen.dart';
import 'package:ourlog/screens/ranking_screen.dart';
import 'package:ourlog/screens/post/community_post_list_screen.dart';
import 'package:ourlog/screens/post/community_post_register_screen.dart';


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
        '/artWork': (context) => const ArtListScreen(),
        '/art/register': (context) => const ArtRegisterScreen(),
        '/customer/termscondition': (context) => const TermsConditionScreen(),
        '/customer/privacypolicy': (context) => const PrivacyPolicyScreen(),
        '/customer/customercenter': (context) => CustomerCenterScreen(
          initialTabIndex: 0,
          isAdmin: false, // 로그인하지 않은 사용자의 기본값
        ),
        '/admin/answer': (context) => AnswerScreen(),
        '/ranking': (context) => const RankingScreen(),

        // New route for community post list
        '/community/list': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final boardType = args?['boardType'] as String?;
          // Pass boardType to CommunityPostListScreen
          return CommunityPostListScreen(boardType: boardType);
        },

        // New route for community post registration
        '/post/register': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final boardType = args?['boardType'] as String?;
          // Pass boardType to CommunityPostRegisterScreen
          return CommunityPostRegisterScreen(boardType: boardType);
        },

        // New route for community post detail
        '/post/detail': (context) {
          final postId = ModalRoute.of(context)!.settings.arguments as int; // Expecting int postId
          // Need to create CommunityPostDetailScreen widget
          return CommunityPostDetailScreen(postId: postId);
        },

        '/mypage/edit': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as int;
          return ProfileEditScreen(userId: userId);
        },
        '/mypage/account/edit':  (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return AccountEditScreen(userId: id);
        },
        '/mypage/purchase-bid':     (context) => const PurchaseBidScreen(),
        '/mypage/sale':             (context) => const SaleScreen(),
        '/mypage/bookmark':         (context) => const BookmarkScreen(),
        '/mypage/account/delete':   (context) => const DeleteUserScreen(),
      },
    );
  }
}
