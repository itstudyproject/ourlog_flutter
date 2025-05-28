import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/post.dart';

const baseUrl = 'http://10.100.204.47:8080/ourlog';

class ApiService {
  // 유저 프로필 불러오기
  static Future<UserProfile> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/profile/$userId'));

    if (response.statusCode == 200) {
      return UserProfile.fromJson(json.decode(response.body));
    } else {
      throw Exception('프로필 로드 실패');
    }
  }

  // 유저 게시물 불러오기
  static Future<List<Post>> getUserPosts(String userId, {int page = 0, int size = 100}) async {
    final response = await http.get(Uri.parse('$baseUrl/followers/getPost/$userId?page=$page&size=$size'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Post.fromJson(e)).toList();
    } else {
      throw Exception('게시물 로드 실패');
    }
  }

  // 팔로잉 상태 체크 API (서버에 이 API가 있어야 합니다)
  static Future<bool> isFollowing(String currentUserId, String writerId) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/followers/isFollowing?followerId=$currentUserId&followingId=$writerId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['isFollowing'] ?? false;
    } else {
      throw Exception('팔로잉 상태 조회 실패');
    }
  }

  // 팔로우 API
  static Future<void> followUser(String currentUserId, String writerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/followers/follow'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'followerId': currentUserId, 'followingId': writerId}),
    );

    if (response.statusCode != 200) {
      throw Exception('팔로우 실패');
    }
  }

  // 언팔로우 API
  static Future<void> unfollowUser(String currentUserId, String writerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/followers/unfollow'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'followerId': currentUserId, 'followingId': writerId}),
    );

    if (response.statusCode != 200) {
      throw Exception('언팔로우 실패');
    }
  }
}
