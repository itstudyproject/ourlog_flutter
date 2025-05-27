import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/trade.dart';

class PostService {
  static const String baseUrl = 'http://your-api-domain.com/api'; // API 도메인으로 변경 필요
  
  // 게시글 목록 가져오기
  static Future<List<Post>> getPosts({int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
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
  static Future<Post> createPost(Post post) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
        body: json.encode(post.toJson()),
      );

      if (response.statusCode == 201) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
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
} 