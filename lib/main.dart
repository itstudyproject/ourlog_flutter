import 'package:flutter/material.dart';
import 'package:ourlog/screens/account_edit_screen.dart';
import 'package:ourlog/screens/art/artRegister_screen.dart';
import 'package:ourlog/screens/art/artlist_screen.dart';
import 'package:ourlog/screens/art/art_detail_screen.dart';
import 'package:ourlog/screens/bookmark_screen.dart';
import 'package:ourlog/screens/chat_list_screen.dart';
import 'package:ourlog/screens/chat_screen.dart';

import 'package:ourlog/screens/customer/answer_screen.dart';
import 'package:ourlog/screens/ranking_screen.dart';


import 'package:ourlog/screens/customer/customer_center_screen.dart';
import 'package:ourlog/screens/customer/privacy_policy_screen.dart';
import 'package:ourlog/screens/customer/terms_condition_screen.dart';
import 'package:ourlog/screens/my_page_screen.dart';
import 'package:ourlog/screens/profile_edit_screen.dart';
import 'package:ourlog/screens/purchase_bid_screen.dart';
import 'package:ourlog/screens/sale_screen.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/delete_user_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'providers/chat_provider.dart';

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
        '/Art': (context) {
          final postId = int.parse(ModalRoute.of(context)!.settings.arguments as String);
          return ArtDetailScreen(postId: postId);
        },
        '/customer/termscondition': (context) => const TermsConditionScreen(),
        '/customer/privacypolicy': (context) => const PrivacyPolicyScreen(),
        '/customer/customercenter': (context) => CustomerCenterScreen(
          initialTabIndex: 0,
          isAdmin: false, // 로그인하지 않은 사용자의 기본값
        ),
        '/admin/answer': (context) => AnswerScreen(), // ✅ 추가
        '/ranking': (context) => const RankingScreen(),
        '/chatList': (context) => const ChatListScreen(), // <-- ChatListScreen 라우트 추가
        
        '/chat': (context) {
  // 라우트 인자(arguments)로 전달된 GroupChannel 객체를 가져옴
  final Object? args = ModalRoute.of(context)!.settings.arguments;
  if (args is GroupChannel) {
    return ChatScreen(channel: args);
  } else {
    // 인자가 null이거나 GroupChannel 타입이 아닐 경우 오류 처리
    debugPrint('Error: Navigated to /chat with invalid arguments: $args');
    return Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: const Center(child: Text('잘못된 채팅 채널 정보입니다.')),
    );
  }
},

        '/mypage/edit': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as int;
          return ProfileEditScreen(userId: userId);
        },
        '/mypage/account/edit':  (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return AccountEditScreen(userId: id);
        },
        // '/mypage/purchase-bid': (ctx) {
        //   final userId = ModalRoute.of(ctx)!.settings.arguments as int;
        //   return PurchaseBidScreen(userId: userId);
        // },
        // '/mypage/sale': (ctx) {
        //   final userId = ModalRoute.of(ctx)!.settings.arguments as int;
        //   return SaleScreen(userId: userId);
        // },
        // '/mypage/bookmark': (ctx) {
        //   final userId = ModalRoute.of(ctx)!.settings.arguments as int;
        //   return BookmarkScreen(userId: userId);
        // },


    //     // 프로필수정 화면으로 라우팅
    // '/mypage/edit': (ctx) {
    // final userId = Provider.of<AuthProvider>(ctx, listen: false).userId;
    // if (userId == null) {
    // // 로그인 안 된 상태면 로그인 페이지로
    // return const LoginScreen();
    // }
    // return ProfileEditScreen(userId: userId);
    // },

        // 회원정보수정
        // '/mypage/account/edit': (c) {
        //   final auth = Provider.of<AuthProvider>(c, listen: false);
        //   final uid  = auth.userId;
        //   if (uid == null) return const LoginScreen();
        //   return AccountEditScreen(userId: uid);
        //   },


    '/mypage/purchase-bid':     (context) => const PurchaseBidScreen(),
    '/mypage/sale':             (context) => const SaleScreen(),
    '/mypage/bookmark':         (context) => const BookmarkScreen(),
    '/mypage/account/delete':   (context) => const DeleteUserScreen(),
      },
    );
  }
}
