import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/services/auth_service.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';

class PostService {
  static const String baseUrl = 'http://10.100.204.157:8080/ourlog';

  static Future<Post?> fetchPost(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/post/read/$id'),
      headers: await getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Post.fromJson(json['postDTO']);
    }
    return null;
  }

  static Future<bool> submitComment({
    required int postId,
    required String content,
  }) async {
    final user = await getUser();
    final response = await http.post(
      Uri.parse('$baseUrl/reply/$postId'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        "content": content,
        "postDTO": {"postId": postId},
        "userDTO": {
          "userId": user['userId'],
          "nickname": user['nickname'],
        }
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteComment(int replyId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/reply/remove/$replyId'),
      headers: await getAuthHeaders(),
    );
    return res.statusCode == 200;
  }

  static Future<bool> updateComment(int replyId, String content) async {
    final res = await http.put(
      Uri.parse('$baseUrl/reply/update/$replyId'),
      headers: await getAuthHeaders(),
      body: jsonEncode({"replyId": replyId, "content": content}),
    );
    return res.statusCode == 200;
  }
}
