import 'package:flutter/material.dart';
import 'package:ourlog/screens/account_edit_screen.dart';
import 'package:ourlog/screens/art/art_register_screen.dart';
import 'package:ourlog/screens/art/artlist_screen.dart';
import 'package:ourlog/screens/art/art_detail_screen.dart';
import 'package:ourlog/screens/bookmark_screen.dart';
import 'package:ourlog/screens/chat_list_screen.dart';
import 'package:ourlog/screens/chat_screen.dart';
import 'package:ourlog/screens/customer/answer_screen.dart';
import 'package:ourlog/screens/post/community_post_detail_screen.dart';
import 'package:ourlog/screens/post/community_post_list_screen.dart';
import 'package:ourlog/screens/post/community_post_register_screen.dart';
import 'package:ourlog/screens/ranking_screen.dart';
import 'package:ourlog/screens/customer/customer_center_screen.dart';
import 'package:ourlog/screens/customer/privacy_policy_screen.dart';
import 'package:ourlog/screens/customer/terms_condition_screen.dart';
import 'package:ourlog/screens/my_page_screen.dart';
import 'package:ourlog/screens/profile_edit_screen.dart';
import 'package:ourlog/screens/purchase_bid_screen.dart';
import 'package:ourlog/screens/sale_screen.dart';
import 'package:ourlog/screens/worker_screen.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:ourlog/providers/auth_provider.dart';
import 'package:ourlog/providers/chat_provider.dart';
import 'screens/art/payment_screen.dart';
import 'screens/art/bid_history_screen.dart';

// screens 폴더에 있는 각 스크린을 import
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/bookmark_screen.dart';
import 'screens/delete_user_screen.dart';
import 'screens/sale_screen.dart';

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
  static const String deleteUser      = '/delete'; // 기존 /delete
  static const String artwork         = '/artWork';
  static const String artRegister     = '/art/register';
  static const String artDetail       = '/Art';
  static const String news            = '/news';
  static const String free            = '/free';
  static const String promotion       = '/promotion';
  static const String request         = '/request';
  static const String postRegister    = '/post/register';
  static const String postList        = '/post/list';
  static const String postDetail      = '/post/detail';
  static const String chatList        = '/chatList';
  static const String chat            = '/chat';
  static const String profile         = '/profile';
  static const String worker          = '/worker';
  static const String artPayment      = '/art/payment';
  static const String artBidHistory   = '/Art/bidhistory';

  // 네임드 라우트 설정
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      login:           (context) => const LoginScreen(),
      register:        (context) => const RegisterScreen(),
      myPage:          (context) => const MyPageScreen(),
      purchaseBid:     (context) => const PurchaseBidScreen(),
      sale:            (context) => const SaleScreen(),
      bookmark:        (context) => const BookmarkScreen(),
      profileEdit: (context) {
        final userId = ModalRoute.of(context)!.settings.arguments as int;
        return ProfileEditScreen(userId: userId);
      },
      accountEdit:     (context) {
        final id = ModalRoute.of(context)!.settings.arguments as int;
        return AccountEditScreen(userId: id);
      },
      accountDelete: (context) => const DeleteUserScreen(),
      termscondition: (context) => const TermsConditionScreen(),
      privacypolicy: (context) => const PrivacyPolicyScreen(),
      customercenter: (context) => CustomerCenterScreen(initialTabIndex: 0,
        isAdmin: false,),
      answer: (context) => AnswerScreen(),
      ranking: (context) => const RankingScreen(),

      // 추가 경로들
      deleteUser: (context) => const DeleteUserScreen(),
      artwork: (context) => const ArtListScreen(),
      artRegister: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final postData = args?['postData'];
        final isReregister = args?['isReregister'] as bool? ?? false;
        return ArtRegisterScreen(postData: postData, isReregister: isReregister);
      },
      artDetail: (context) {
        final postId = int.parse(
          ModalRoute.of(context)!.settings.arguments as String,
        );
        return ArtDetailScreen(postId: postId);
      },
      news: (context) {
        return const CommunityPostListScreen(boardType: 'news');
      },
      free: (context) {
        return const CommunityPostListScreen(boardType: 'free');
      },
      promotion: (context) {
        return const CommunityPostListScreen(boardType: 'promotion');
      },
      request: (context) {
        return const CommunityPostListScreen(boardType: 'request');
      },
      postRegister: (context) {
        final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final boardType = args?['boardType'] as String?;
        return CommunityPostRegisterScreen(boardType: boardType);
      },
      postList: (context) {
        final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final boardType = args?['boardType'] as String?;
        return CommunityPostListScreen(boardType: boardType);
      },
      postDetail: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final postId = args?['postId'] as int?;
        if (postId == null) {
          return const Scaffold(body: Center(child: Text('게시글 정보를 찾을 수 없습니다.')));
        }
        return CommunityPostDetailScreen(postId: postId);
      },
      chatList: (context) => const ChatListScreen(),
      chat: (context) {
        final Object? args = ModalRoute.of(context)!.settings.arguments;
        if (args is GroupChannel) {
          return ChatScreen(channel: args);
        } else {
          debugPrint('Error: Navigated to /chat with invalid arguments: $args');
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('잘못된 채팅 채널 정보입니다.')),
          );
        }
      },
      profile: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        final userId = int.parse(args as String);
        final currentUserId =
            Provider.of<AuthProvider>(context, listen: false).userId;
        if (currentUserId == null) {
          return const LoginScreen();
        }
        return WorkerScreen(userId: userId, currentUserId: currentUserId);
      },
      worker: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;
        if (args == null || args is! Map<String, dynamic>) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('잘못된 사용자 정보가 전달되었습니다.')),
          );
        }
        final userIdRaw = args['userId'];
        final currentUserIdRaw = args['currentUserId'];
        final int? userId = userIdRaw is int
            ? userIdRaw
            : int.tryParse(userIdRaw?.toString() ?? '');
        final int? currentUserId = currentUserIdRaw is int
            ? currentUserIdRaw
            : int.tryParse(currentUserIdRaw?.toString() ?? '');
        if (userId == null || currentUserId == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('오류')),
            body: const Center(child: Text('사용자 ID가 올바르지 않습니다.')),
          );
        }
        return WorkerScreen(userId: userId, currentUserId: currentUserId);
      },
      artPayment: (context) => const PaymentScreen(),
      artBidHistory: (context) => const BidHistoryScreen(),
    };
  }
} 