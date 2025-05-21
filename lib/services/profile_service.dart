// lib/services/profile_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class ProfileService {
  static const String _baseUrl = 'http://10.100.204.124:8080/ourlog';

  /// 프로필 조회
  Future<UserProfile> fetchProfile(int userId) async {
    try {
      print('★★★ fetchProfile() 진입 userId=$userId ★★★');

      final prefs = await SharedPreferences.getInstance();
      print('prefs OK');

      final token = prefs.getString('token') ?? '';
      print('🔥 토큰 값: "$token" (length=${token.length})');

      final url = '$_baseUrl/profile/get/$userId';
      print('▶▶ GET $url');
      print('    Authorization 헤더: Bearer $token');

      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('◀◀ ${resp.statusCode} ${resp.body}');
      if (resp.statusCode != 200) {
        throw Exception('프로필 조회 실패 (${resp.statusCode})');
      }

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (e, st) {
      print('⚠️ fetchProfile 예외 발생: $e');
      print(st);
      rethrow;
    }
  }

  /// 프로필 수정
  Future<UserProfile> updateProfile(
      int userId, {
        String? nickname,
        String? introduction,
        String? originImagePath,
      }) async {
    try {
      print('★★★ updateProfile() 진입 userId=$userId ★★★');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      print('🔥 토큰 값: "$token" (length=${token.length})');

      final url = '$_baseUrl/profile/update/$userId';

      final body = <String, dynamic>{};
      if (nickname       != null) body['nickname']        = nickname;
      if (introduction   != null) body['introduction']    = introduction;
      if (originImagePath!= null) body['originImagePath'] = originImagePath;

      print('▶▶ PATCH $url');
      print('    Authorization 헤더: Bearer $token');
      print('    Body: $body');

      final resp = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('◀◀ ${resp.statusCode} ${resp.body}');
      if (resp.statusCode != 200) {
        throw Exception('프로필 업데이트 실패 (${resp.statusCode})');
      }

      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (e, st) {
      print('⚠️ updateProfile 예외 발생: $e');
      print(st);
      rethrow;
    }
  }
}


//   /// 프로필 수정
//   Future<UserProfile> updateProfile(
//       int userId, {
//         String? nickname,
//         String? introduction,
//         String? originImagePath,
//       }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';
//     final url = '$_baseUrl/profile/update/$userId';
//
//     // 수정할 필드만 body에 담기
//     final body = <String, dynamic>{};
//     if (nickname       != null) body['nickname']       = nickname;
//     if (introduction   != null) body['introduction']   = introduction;
//     if (originImagePath!= null) body['originImagePath']= originImagePath;
//
//     // 요청 로그
//     print('▶▶ PATCH $url');
//     print('    Authorization: Bearer $token');
//     print('    Body: $body');
//
//     final resp = await http.patch(
//       Uri.parse(url),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: jsonEncode(body),
//     );
//
//     // 응답 로그
//     print('◀◀ ${resp.statusCode} ${resp.body}');
//     if (resp.statusCode != 200) {
//       throw Exception('프로필 업데이트 실패 (${resp.statusCode})');
//     }
//
//     final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
//     return UserProfile.fromJson(jsonMap);
//   }
//}
