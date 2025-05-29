import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/models/post/post.dart';
import 'package:ourlog/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
  static const String baseUrl = 'http://10.100.204.157:8080/ourlog';

  // 게시글 목록 가져오기 (이전과 동일)
  static Future<List<Post>> getPosts({int page = 0, int size = 10, int? boardNo}) async {
    try {
      final String? token = await _getToken();
      final url = boardNo != null
          ? '$baseUrl/post/list?boardNo=$boardNo&page=${page + 1}&size=$size'
          : '$baseUrl/post/list?page=${page + 1}&size=$size';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('pageResultDTO')) {
          final List<dynamic> jsonList = responseData['pageResultDTO']['dtoList'];
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

  // 게시글 상세 조회 (수정된 부분)
  static Future<Post> getPostById(int postId) async {
    try {
      final String? token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/post/read/$postId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body); // 응답 본문을 Map으로 디코딩

        // 백엔드에서 "postDTO"라는 키 아래에 실제 게시물 데이터가 있으므로, 해당 키로 접근합니다.
        if (responseData.containsKey('postDTO')) {
          return Post.fromJson(responseData['postDTO']); // 'postDTO' 키의 값으로 Post.fromJson 호출
        } else {
          // 'postDTO' 키가 없을 경우 에러 처리
          throw Exception('Failed to load post: "postDTO" key not found in response.');
        }
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  // 새 게시글 작성 (이전과 동일)
  static Future<dynamic> createPost(Post post) async {
    try {
      final response = await AuthService.authenticatedPost(
        '/post/register',
        await _getToken(),
        body: post.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseBody = json.decode(response.body);
        return responseBody;
      } else {
        String errorMessage = 'Failed to create post: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = 'Failed to create post: ${errorData['message']}';
          } else {
            errorMessage = 'Failed to create post: ${response.body} (Status: ${response.statusCode})';
          }
        } catch (e) {
          // If JSON parsing fails, use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // 게시글 수정 (이전과 동일)
  static Future<Post> updatePost(Post post) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/post/${post.postId}'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
        body: json.encode(post.toJson()),
      );

      if (response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // 게시글 삭제 (이전과 동일)
  static Future<void> deletePost(int postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/post/$postId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // 게시글 검색 (이전과 동일)
  static Future<List<Post>> searchPosts(String keyword, {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/post/search?keyword=$keyword&page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
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

  // 사용자의 게시글 목록 가져오기 (이전과 동일)
  static Future<List<Post>> getUserPosts(int userId, {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/post/user/$userId?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token',
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

  // Helper to get token (이전과 동일)
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}