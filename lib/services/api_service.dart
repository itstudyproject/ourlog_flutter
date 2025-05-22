import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/post.dart';

const baseUrl = 'http://10.100.204.47:8080/ourlog';

// 유저 프로필 불러오기
Future<UserProfile> fetchUserProfile(int userId) async {
  final response = await http.get(Uri.parse('$baseUrl/user/profile/$userId'));

  if (response.statusCode == 200) {
    return UserProfile.fromJson(json.decode(response.body));
  } else {
    throw Exception('프로필 로드 실패');
  }
}

// 유저 게시물 불러오기
Future<List<Post>> fetchUserPosts(int userId, {int page = 0, int size = 9}) async {
  final response = await http.get(Uri.parse('$baseUrl/followers/getPost/$userId?page=$page&size=$size'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((e) => Post.fromJson(e)).toList();
  } else {
    throw Exception('게시물 로드 실패');
  }
}

// 좋아요 상태 불러오기
Future<LikeStatus> fetchLikeStatus(int userId, int postId) async {
  final response = await http.get(Uri.parse('$baseUrl/favorites/status?userId=$userId&postId=$postId'));

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return LikeStatus(
      liked: jsonData['liked'],
      count: jsonData['count'],
    );
  } else {
    throw Exception('좋아요 상태 조회 실패');
  }
}

// 팔로우/언팔로우 토글
Future<bool> toggleFollow(int followerId, int followingId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/followers/toggle'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'followerId': followerId, 'followingId': followingId}),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body)['isFollowing'];
  } else {
    throw Exception('팔로우 실패');
  }
}
