// lib/services/profile_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  // UserProfileController의 @RequestMapping("/profile") 까지 포함
  static const String _baseUrl = 'http://10.100.204.47:8080/ourlog/profile';

  /// 1) 프로필 조회
  Future<UserProfile> fetchProfile(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/get/$userId');

    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('프로필 조회 실패 (${resp.statusCode})');
    }
    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserProfile.fromJson(jsonMap);
  }

  /// 2) 프로필 사진 업로드 (multipart/form-data)
  Future<String> uploadProfileImage(int userId, File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/upload-image/$userId');

    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('이미지 업로드 실패 (${resp.statusCode})');
    }
    final Map<String, dynamic> json = jsonDecode(resp.body);
    return json['originImagePath'] as String;
  }

  /// 3) 프로필 수정 (PUT /profile/edit/{userId})
  ///
  /// 변경된 필드만 named-parameter 로 전달하고,
  /// 성공 시 업데이트된 UserProfile DTO를 반환합니다.
  Future<UserProfile> updateProfile(
      int userId, {
        String? nickname,
        String? introduction,
        String? originImagePath,
        String? thumbnailImagePath,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/edit/$userId');

    final body = <String, dynamic>{};
    if (nickname        != null) body['nickname']        = nickname;
    if (introduction    != null) body['introduction']    = introduction;
    if (originImagePath != null) body['originImagePath'] = originImagePath;
    if (thumbnailImagePath != null) body['thumbnailImagePath'] = thumbnailImagePath;

    final resp = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    print('★★★ updateProfile PUT ${uri.toString()}');
    print('    Request body: ${jsonEncode(body)}');

    if (resp.statusCode != 200) {
      throw Exception('프로필 업데이트 실패 (${resp.statusCode})');
    }
    final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserProfile.fromJson(jsonMap);
  }
}