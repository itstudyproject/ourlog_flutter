import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/models/post.dart';
import 'package:ourlog/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
  static const String baseUrl = 'http://10.100.204.144:8080/ourlog';

  /// 저장된 JWT 토큰을 SharedPreferences에서 가져옵니다.
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 게시글 목록 가져오기 (페이징 + 선택적 boardNo)
  static Future<List<Post>> getPosts({
    int page = 0,
    int size = 10,
    int? boardNo,
  }) async {
    try {
      final String? token = await _getToken();
      final uri = Uri.parse(boardNo != null
          ? '$baseUrl/post/list?boardNo=$boardNo&page=${page + 1}&size=$size'
          : '$baseUrl/post/list?page=${page + 1}&size=$size');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map && responseData.containsKey('pageResultDTO')) {
          final List<dynamic> jsonList =
          responseData['pageResultDTO']['dtoList'];
          return jsonList.map((json) => Post.fromJson(json)).toList();
        } else if (responseData is List) {
          return responseData.map((json) => Post.fromJson(json)).toList();
        } else {
          throw Exception('Unknown response format for getPosts');
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  /// 게시글 상세 조회
  static Future<Post> getPostById(int postId) async {
    try {
      final String? token = await _getToken();
      final uri = Uri.parse('$baseUrl/post/read/$postId');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(response.body);

        if (responseData.containsKey('postDTO')) {
          return Post.fromJson(responseData['postDTO']);
        } else {
          throw Exception(
              'Failed to load post: "postDTO" key not found in response.');
        }
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  /// 새 게시글 작성
  static Future<dynamic> createPost(Post post) async {
    try {
      final String? token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      // AuthService.authenticatedPost를 사용해 JWT 헤더를 붙여서 전송합니다.
      final response = await AuthService.authenticatedPost(
        '/post/register',
        token,
        body: post.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        var errorMessage = 'Failed to create post: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = 'Failed to create post: ${errorData['message']}';
          } else {
            errorMessage =
            'Failed to create post: ${response.body} (Status: ${response.statusCode})';
          }
        } catch (_) {
          // JSON 파싱 실패 시 기본 에러 메시지 사용
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// 게시글 수정
  static Future<void> updatePost(Post post) async {
    try {
      final String? token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      // 백엔드의 수정 엔드포인트는 "/post/modify" 입니다.
      final uri = Uri.parse('$baseUrl/post/modify');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(post.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
      // 성공 시 별도 반환값 없음
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// 게시글 삭제
  static Future<void> deletePost(int postId) async {
    try {
      final String? token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      // 백엔드의 삭제 엔드포인트는 "/post/remove/{postId}" 입니다.
      final uri = Uri.parse('$baseUrl/post/remove/$postId');
      print('[DEBUG] DELETE $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '[DEBUG] deletePost response: statusCode=${response.statusCode}, body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// 게시글 검색
  static Future<List<Post>> searchPosts(
      String keyword, {
        int page = 0,
        int size = 10,
      }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/post/search?keyword=$keyword&page=$page&size=$size');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  /// 사용자의 게시글 목록 가져오기
  static Future<List<Post>> getUserPosts(
      int userId, {
        int page = 0,
        int size = 10,
      }) async {
    try {
      final String? token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found.');
      }

      final uri =
      Uri.parse('$baseUrl/post/user/$userId?page=$page&size=$size');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user posts: $e');
    }
  }
}
