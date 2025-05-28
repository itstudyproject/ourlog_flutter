import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.100.204.47:8080/';
  static String? authToken;  // 로그인 후 받아서 저장할 토큰

  // 토큰 설정 함수 (로그인 후 호출)
  static void setAuthToken(String token) {
    authToken = token;
  }

  // 프로필 정보 가져오기 (토큰 포함)
  static Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ourlog/profile/get/$userId'),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  // 게시물 정보 가져오기 (토큰 포함)
  static Future<Map<String, dynamic>> fetchUserPosts(String userId, int page, int size) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ourlog/posts/user/$userId?page=$page&size=$size'),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('게시물 정보를 불러오지 못했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  // 팔로우/언팔로우 토글 (토큰 포함)
  static Future<void> toggleFollow(String userId, bool isCurrentlyFollowing) async {
    final url = isCurrentlyFollowing
        ? '$baseUrl/ourlog/unfollow'
        : '$baseUrl/ourlog/follow';

    final response = await http.post(
      Uri.parse(url),
      headers: _buildHeaders(contentType: true),
      body: jsonEncode({'followingUserId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('팔로우/언팔로우 처리 실패 상태 코드: ${response.statusCode}');
    }
  }

  // 좋아요 토글 (토큰 포함)
  static Future<bool> toggleLike(int postId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ourlog/like/$postId'),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['liked'] ?? false;
    } else {
      throw Exception('좋아요 처리 실패 상태 코드: ${response.statusCode}');
    }
  }

  // 요청 헤더 생성 함수
  static Map<String, String> _buildHeaders({bool contentType = false}) {
    final headers = <String, String>{};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (contentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }
}