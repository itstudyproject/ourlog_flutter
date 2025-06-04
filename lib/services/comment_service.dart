// lib/services/comment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comment.dart';

class CommentService {
  static const String baseUrl = 'http://10.100.204.157:8080/ourlog';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 1) 댓글 목록 조회
  static Future<List<Comment>> getComments(int postId) async {
    final token = await _getToken();
    final url = '$baseUrl/reply/all/$postId';

    print('[CommentService.getComments] URL: $url');
    print('[CommentService.getComments] Authorization: Bearer $token');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('[CommentService.getComments] 상태코드: ${response.statusCode}');
    print('[CommentService.getComments] 바디: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('댓글 목록 로드 실패: ${response.statusCode}');
    }
  }

  /// 2) 댓글 등록 (POST)
  static Future<int> addComment(int postId, String content) async {
    final token = await _getToken();
    final url = '$baseUrl/reply/$postId';

    print('[CommentService.addComment] URL: $url');
    print('[CommentService.addComment] Authorization: Bearer $token');

    final body = json.encode({
      'content': content,
      'postDTO': {
        'postId': postId,
      },
      // userDTO는 백엔드가 토큰에서 가져간다고 가정
    });
    print('[CommentService.addComment] 요청 바디: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('[CommentService.addComment] 상태코드: ${response.statusCode}');
    print('[CommentService.addComment] 바디: ${response.body}');

    if (response.statusCode == 201) {
      return int.parse(response.body);
    } else {
      throw Exception('댓글 등록 실패: ${response.statusCode}');
    }
  }

  /// 3) 댓글 수정 (PUT)
  static Future<int> updateComment(int replyId, int postId, String editedContent) async {
    final token = await _getToken();
    final url = '$baseUrl/reply/update/$replyId';

    print('[CommentService.updateComment] URL: $url');
    print('[CommentService.updateComment] Authorization: Bearer $token');

    final body = json.encode({
      'replyId': replyId,
      'content': editedContent,
      'postDTO': {
        'postId': postId,
      },
      // 백엔드가 userDTO를 토큰에서 알아온다고 가정
    });
    print('[CommentService.updateComment] 요청 바디: $body');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print('[CommentService.updateComment] 상태코드: ${response.statusCode}');
    print('[CommentService.updateComment] 바디: ${response.body}');

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('댓글 수정 실패: ${response.statusCode}');
    }
  }

  /// 4) 댓글 삭제 (DELETE)
  static Future<int> deleteComment(int replyId) async {
    final token = await _getToken();
    final url = '$baseUrl/reply/remove/$replyId';

    print('[CommentService.deleteComment] URL: $url');
    print('[CommentService.deleteComment] Authorization: Bearer $token');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('[CommentService.deleteComment] 상태코드: ${response.statusCode}');
    print('[CommentService.deleteComment] 바디: ${response.body}');

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      throw Exception('댓글 삭제 실패: ${response.statusCode}');
    }
  }
}
