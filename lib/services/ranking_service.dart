import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class RankingService {
  static const String baseUrl = "http://10.100.204.47:8080/ourlog/ranking";

  // 인증 토큰과 헤더를 내부에서 가져오는 메서드
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Post>> fetchRanking(String type) async {
    final uri = Uri.parse('$baseUrl?type=$type');
    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final posts = data.map((item) => Post.fromJson(item)).toList();

      if (type == "followers") {
        // 중복 userId 제거
        final Map<int?, Post> uniqueMap = {};
        for (var post in posts) {
          if (!uniqueMap.containsKey(post.userId)) {
            uniqueMap[post.userId] = post;
          }
        }
        final uniqueList = uniqueMap.values.toList();
        uniqueList.sort((a, b) => (b.followers ?? 0) - (a.followers ?? 0));
        return uniqueList;
      } else if (type == 'views') {
        posts.sort((a, b) => (b.views ?? 0) - (a.views ?? 0));
        return posts;
      } else if (type == 'downloads') {
        posts.sort((a, b) => (b.downloads ?? 0) - (a.downloads ?? 0));
        return posts;
      }
      return posts;
    } else if (response.statusCode == 403) {
      throw Exception("권한 없음");
    } else {
      throw Exception("랭킹 데이터 요청 실패: ${response.statusCode}");
    }
  }
}
