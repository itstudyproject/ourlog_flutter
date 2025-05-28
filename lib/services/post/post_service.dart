import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/models/post/post.dart';
import 'package:ourlog/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
  static const String baseUrl = 'http://10.100.204.157:8080/ourlog'; // Update base URL to the correct one

  // 게시글 목록 가져오기
  static Future<List<Post>> getPosts({int page = 0, int size = 10, int? boardNo}) async {
    try {
      final String? token = await _getToken(); // Get token

      // Construct URL with optional boardNo
      final url = boardNo != null
          ? '$baseUrl/post/list?boardNo=$boardNo&page=${page + 1}&size=$size'
          : '$baseUrl/post/list?page=${page + 1}&size=$size'; // Use /post/list even if boardNo is null, send page + 1

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', // Add Authorization header if token exists
        },
      );

      if (response.statusCode == 200) {
         // Handle different response structures for list endpoint
         final dynamic responseData = json.decode(response.body);

         if (responseData is Map && responseData.containsKey('pageResultDTO')) {
            // Assumes backend returns a structure like { 'pageResultDTO': { 'dtoList': [...] } }
             final List<dynamic> jsonList = responseData['pageResultDTO']['dtoList'];
             return jsonList.map((json) => Post.fromJson(json)).toList();
         } else if (responseData is List) {
            // Assumes backend returns a direct list of posts
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

  // 게시글 상세 조회
  static Future<Post> getPostById(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  // 새 게시글 작성
  static Future<dynamic> createPost(Post post) async {
    try {
      final response = await AuthService.authenticatedPost(
        '/post/register',
        await _getToken(),
        body: post.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decode the response body
        final dynamic responseBody = json.decode(response.body);
        // Return the decoded body directly. The caller will handle the type.
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

  // 게시글 수정
  static Future<Post> updatePost(Post post) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/${post.postId}'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
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

  // 게시글 삭제
  static Future<void> deletePost(int postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // 게시글 검색
  static Future<List<Post>> searchPosts(String keyword, {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/search?keyword=$keyword&page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
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

  // 사용자의 게시글 목록 가져오기
  static Future<List<Post>> getUserPosts(int userId, {int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/user/$userId?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
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

  // Helper to get token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
} 