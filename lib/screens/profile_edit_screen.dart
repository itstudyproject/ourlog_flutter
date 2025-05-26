import 'package:flutter/material.dart';

import '../screens/post/post_list_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/post/post_register_screen.dart';
import '../screens/post/post_modify_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const PostListScreen());

    case '/post/list':
      final boardNo = settings.arguments as int? ?? 2;
      return MaterialPageRoute(
        builder: (_) => PostListScreen(boardNo: boardNo),
      );

    case '/post/detail':
      final postId = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => PostDetailScreen(postId: postId),
      );

    case '/post/register':
      return MaterialPageRoute(builder: (_) => const PostRegisterScreen());

    case '/post/modify':
      final postId = settings.arguments as int;
      return MaterialPageRoute(
        builder: (_) => PostModifyScreen(postId: postId),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('정의되지 않은 경로: ${settings.name}')),
        ),
      );
  }
}