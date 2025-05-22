// lib/services/user_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  /// 사용자 정보 조회
  static Future<User> fetchUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final resp = await http.get(
      Uri.parse('http://localhost:8080/ourlog/profile/get/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('사용자 정보 조회 실패: ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  /// 사용자 정보(비밀번호/연락처) 수정
  static Future<void> updateUserInfo(
      int userId, {
        String? password,
        String? mobile,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final body = <String, dynamic>{};
    if (password != null) body['password'] = password;
    if (mobile   != null) body['mobile']   = mobile;

    final resp = await http.patch(
      Uri.parse('http://localhost:8080/ourlog/profile/accountEdit/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (resp.statusCode != 200) {
      throw Exception('회원정보 수정 실패: ${resp.statusCode}');
    }
  }
}
