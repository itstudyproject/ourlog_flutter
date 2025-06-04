// lib/services/my_post_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class MyPostService {
  final String _baseUrl = 'http://10.100.204.144:8080/ourlog';

  /// 사용자가 작성한 글 목록을 가져오는 API 호출
  Future<List<Post>> fetchMyPosts(int userId, String token) async {
    // 백엔드가 사용하는 정확한 경로: /profile/posts/user/{userId}
    final uri = Uri.parse('$_baseUrl/profile/posts/user/$userId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = json.decode(response.body);
      return body.map((e) => Post.fromJson(e)).toList();
    } else {
      throw Exception('내 글 목록 불러오기 실패 (${response.statusCode})');
    }
  }

  /// 글 삭제에도 인증이 필요하다면, URL을 알맞게 바꿔 주세요.
  Future<void> deletePost(int postId, String token) async {
    // 예시: 삭제 엔드포인트가 /profile/posts/{postId}라면
    final uri = Uri.parse('$_baseUrl/profile/posts/$postId');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('글 삭제 실패 (${response.statusCode})');
    }
  }
}



