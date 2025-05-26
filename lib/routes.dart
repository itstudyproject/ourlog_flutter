import 'package:flutter/material.dart';
import 'package:ourlog/screens/work_screen.dart';
import 'screens/home_screen.dart';
// screens 폴더에 있는 각 스크린을 import
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_page_screen.dart';
// import 'screens/purchase_bid_screen.dart';
import 'screens/sale_screen.dart';
import 'screens/bookmark_screen.dart';
import 'screens/profile_edit_screen.dart';
// import 'screens/account_edit_screen.dart';
import 'screens/delete_user_screen.dart';

// 앱의 모든 경로를 관리하는 클래스
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String worker = '/worker';
  static const String register = '/register';
  static const String myPage = '/mypage';
  static const String purchaseBid = '/mypage/purchase-bid';
  static const String sale = '/mypage/sale';
  static const String bookmark = '/mypage/bookmark';
  static const String profileEdit = '/mypage/edit';
  static const String accountEdit = '/mypage/account/edit';
  static const String accountDelete = '/mypage/account/delete';

  // 여기에 추가 경로 정의

  // 네임드 라우트 설정
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      myPage: (context) => const MyPageScreen(),
      // purchaseBid:     (context) => const PurchaseBidScreen(),
      sale: (context) => const SaleScreen(),
      bookmark: (context) => const BookmarkScreen(),
      // accountEdit:     (context) => const AccountEditScreen(),
      accountDelete: (context) => const DeleteUserScreen(),
      // 여기에 추가 경로 추가

      /// ✅ WorkScreen은 arguments로 동적 파라미터를 받아야 하므로 const로 생성 못함
      worker: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
        if (args == null || !args.containsKey('userId') || !args.containsKey('currentUserId')) {
          return const Scaffold(body: Center(child: Text('잘못된 접근입니다')));
        }
        return WorkScreen( // ✅ 수정됨
          writerId: args['userId']!,          // ✅ 매개변수 이름도 맞춤
          currentUserId: args['currentUserId']!,
        );
      },
    };
  }