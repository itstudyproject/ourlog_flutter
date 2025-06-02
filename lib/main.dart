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

import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/delete_user_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'providers/chat_provider.dart';
import 'screens/art/payment_screen.dart';
import 'screens/art/bid_history_screen.dart';

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
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/delete': (context) => const DeleteUserScreen(),
        '/mypage': (context) => const MyPageScreen(),
        '/artWork': (context) => const ArtListScreen(),
        '/art/register': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final postData = args?['postData'];
          final isReregister = args?['isReregister'] as bool? ?? false;

          return ArtRegisterScreen(postData: postData, isReregister: isReregister);
        },
        '/Art': (context) {
          final postId = int.parse(
            ModalRoute.of(context)!.settings.arguments as String,
          );
          return ArtDetailScreen(postId: postId);
        },
        '/customer/termscondition': (context) => const TermsConditionScreen(),
        '/customer/privacypolicy': (context) => const PrivacyPolicyScreen(),
        '/customer/customercenter': (context) => CustomerCenterScreen(
          initialTabIndex: 0,
          isAdmin: false,
        ),
        '/admin/answer': (context) => AnswerScreen(),

        // ─────────── 커뮤니티 4개 라우트 추가 ───────────
        '/news': (context) {
          // "새소식" 게시판
          return const CommunityPostListScreen(boardType: 'news');
        },
        '/free': (context) {
          // "자유게시판"
          return const CommunityPostListScreen(boardType: 'free');
        },
        '/promotion': (context) {
          // "홍보 게시판"
          return const CommunityPostListScreen(boardType: 'promotion');
        },
        '/request': (context) {
          // "요청 게시판"
          return const CommunityPostListScreen(boardType: 'request');
        },

        // 기존에 있던 community/list 라우트도 남겨둡니다. 필요시 boardType 전달 방식으로 사용 가능
        '/community/list': (context) {
          final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final boardType = args?['boardType'] as String?;
          return CommunityPostListScreen(boardType: boardType);
        },

        '/community/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final postId = args?['postId'] as int?;
          if (postId == null) {
            return const Scaffold(body: Center(child: Text('게시글 정보를 찾을 수 없습니다.')));
          }
          return CommunityPostDetailScreen(postId: postId);
        },

        '/ranking': (context) => const RankingScreen(),
        '/chatList': (context) => const ChatListScreen(),

        '/chat': (context) {
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

        '/profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final userId = int.parse(args as String);
          final currentUserId =
              Provider.of<AuthProvider>(context, listen: false).userId;
          if (currentUserId == null) {
            return const LoginScreen();
          }
          return WorkerScreen(userId: userId, currentUserId: currentUserId);
        },

        '/worker': (context) {
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
        '/mypage/edit': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as int;
          return ProfileEditScreen(userId: userId);
        },
        '/mypage/account/edit': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return AccountEditScreen(userId: id);
        },
        '/mypage/purchase-bid': (context) => const PurchaseBidScreen(),
        '/mypage/sale': (context) => const SaleScreen(),
        '/mypage/bookmark': (context) => const BookmarkScreen(),
        '/mypage/account/delete': (context) => const DeleteUserScreen(),
        '/art/payment': (context) => const PaymentScreen(),
        '/Art/bidhistory': (context) => const BidHistoryScreen(),
      },
      // 없는 라우트를 호출할 때 홈 화면으로 보낼 수도 있습니다.
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}
