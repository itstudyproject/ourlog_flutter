import 'package:flutter/material.dart';
import 'package:ourlog/screens/customer/answer_screen.dart';
import 'package:ourlog/screens/customer/customer_center_screen.dart';
import 'package:ourlog/screens/customer/privacy_policy_screen.dart';
import 'package:ourlog/screens/customer/terms_condition_screen.dart';
import 'package:ourlog/screens/ranking_screen.dart';
import 'screens/home_screen.dart';
// screens 폴더에 있는 각 스크린을 import
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_page_screen.dart';
// import 'screens/purchase_bid_screen.dart';
import 'screens/sale_screen.dart';
import 'screens/bookmark_screen.dart';
import 'screens/delete_user_screen.dart';

// 앱의 모든 경로를 관리하는 클래스
class AppRoutes {
  static const String home = '/';
  static const String login           = '/login';
  static const String register        = '/register';
  static const String myPage          = '/mypage';
  static const String purchaseBid     = '/mypage/purchase-bid';
  static const String sale            = '/mypage/sale';
  static const String bookmark        = '/mypage/bookmark';
  static const String profileEdit     = '/mypage/edit';
  static const String accountEdit     = '/mypage/account/edit';
  static const String accountDelete   = '/mypage/account/delete';

  static const String termscondition   = '/customer/termscondition';
  static const String privacypolicy   = '/customer/privacypolicy';
  static const String customercenter   = '/customer/customercenter';
  static const String answer   = '/admin/answer';

  static const String ranking   = '/ranking';

  // 여기에 추가 경로 정의

  // 네임드 라우트 설정
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      login:           (context) => const LoginScreen(),
      register:        (context) => const RegisterScreen(),
      myPage:          (context) => const MyPageScreen(),
      // purchaseBid:     (context) => const PurchaseBidScreen(),
      sale:            (context) => const SaleScreen(),
      bookmark:        (context) => const BookmarkScreen(),
      // accountEdit:     (context) => const AccountEditScreen(),
      accountDelete: (context) => const DeleteUserScreen(),
      // 여기에 추가 경로 추가
      termscondition: (context) => const TermsConditionScreen(),

      privacypolicy: (context) => const PrivacyPolicyScreen(),
      customercenter: (context) => CustomerCenterScreen(initialTabIndex: 0,
        isAdmin: false,),
      answer: (context) => AnswerScreen(),
      ranking: (context) => const RankingScreen(),

    };
  }
} 