// lib/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String _baseUrl = 'http://10.100.204.171:8080/ourlog';

  /// 1) 회원 기본 정보 조회
  ///    - mobile만 필요하시면, DTO에서 mobile만 꺼내쓰시면 됩니다.
  static Future<User> fetchUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/profile/get/$userId');

    final resp = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode != 200) {
      throw Exception('사용자 정보 조회 실패 (${resp.statusCode})');
    }
    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    return User.fromJson(jsonMap);
  }

  /// 2) 회원정보 수정 (비밀번호, 연락처)
  ///    PATCH /profile/accountEdit/{userId}
  static Future<void> updateUserInfo(
      int userId, {
        String? password,
        String? mobile,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/profile/accountEdit/$userId');

    final body = <String, dynamic>{};
    if (password != null) body['password'] = password;
    if (mobile   != null) body['mobile']   = mobile;

    final resp = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('회원정보 수정 실패 (${resp.statusCode}): ${resp.body}');
    }
  }
}