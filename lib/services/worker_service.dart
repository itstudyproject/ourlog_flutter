import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkerService {
  static const String baseUrl = 'http://10.100.204.189:8080/ourlog'; // 실제 API URL

  // 공통 헤더 빌드 (토큰 포함)
  static Future<Map<String, String>> _buildHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 유저 프로필 조회
  static Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final headers = await _buildHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/profile/get/$userId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('프로필 정보를 불러오지 못했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  // 유저 게시물 페이지네이션 조회
  static Future<Map<String, dynamic>> fetchUserPosts(int userId, int page, int size) async {
    if (page < 0) {
      throw ArgumentError('page 값은 0 이상이어야 합니다. 전달된 값: $page');
    }

    final headers = await _buildHeaders();
    final url = '$baseUrl/post/list?userId=$userId&page=$page&size=$size';

    print('Request URL: $url');
    print('Headers: $headers');

    final response = await http.get(Uri.parse(url), headers: headers);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data; // content만 아니라 전체 Map 반환
    } else {
      throw Exception('게시물 정보를 불러오지 못했습니다. 상태 코드: ${response.statusCode}');
    }
  }



  // 팔로우 토글 (로그인 유저 id, 작가 id, 현재 팔로우 여부)
  static Future<void> toggleFollow(int fromUserId, int toUserId, bool isFollowing) async {
    final headers = await _buildHeaders();

    final url = isFollowing
        ? Uri.parse('$baseUrl/followers/$fromUserId/unfollow/$toUserId')
        : Uri.parse('$baseUrl/followers/$fromUserId/follow/$toUserId');

    final response = isFollowing
        ? await http.delete(url, headers: headers)
        : await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      final msg = json.decode(response.body)['message'];
      print('✅ Follow 처리 결과: $msg');
    } else if (response.statusCode == 403) {
      throw Exception('❌ 권한 없음 (인증된 사용자와 불일치)');
    } else {
      throw Exception('❌ Follow 처리 실패: ${response.statusCode}');
    }
  }

  static Future<bool> isFollowing(int fromUserId, int toUserId) async {
    final headers = await _buildHeaders();

    final url = Uri.parse('$baseUrl/followers/status/isFollowing/$fromUserId/$toUserId');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as bool;
    } else {
      throw Exception('팔로우 상태 확인 실패: ${response.statusCode}');
    }
  }

  // 좋아요 토글 (로그인 유저 id, 게시물 id) - true/false 리턴
  static Future<bool> toggleLike(int loggedInUserId, int postId) async {
    final headers = await _buildHeaders();
    final url = Uri.parse('$baseUrl/favorites/toggle');
    final body = json.encode({
      'userId': loggedInUserId,
      'postId': postId,
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    print('좋아요 토글 응답: ${response.body}'); // 여기서 응답 내용 확인

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data.containsKey('favorited') && data['favorited'] is bool) {
        return data['favorited'] as bool;
      } else {
        // liked 필드 없을 때 응답 데이터 전체 출력
        print('서버 응답에 liked 필드가 없거나 잘못됨: $data');
        throw Exception('서버 응답에 liked 필드가 없거나 잘못됨');
      }
    } else {
      throw Exception('좋아요 처리 실패 상태 코드: ${response.statusCode}');
    }
  }
}
