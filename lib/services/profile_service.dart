// lib/services/profile_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

class ProfileService {
  // UserProfileController의 @RequestMapping("/profile") 까지 포함
  static const String _baseUrl = 'http://10.100.204.124:8080/ourlog/profile';

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
      ..headers['Authorization'] = 'Bearer $token';

    String? getMimeType(String filePath) {
      final ext = p.extension(filePath).toLowerCase();
      switch (ext) {
        case '.jpg':
        case '.jpeg':
          return 'image/jpeg';
        case '.png':
          return 'image/png';
        case '.gif':
          return 'image/gif';
        // 필요에 따라 다른 이미지 포맷 추가
        default:
          return null; // 또는 'application/octet-stream'
      }
    }

    var contentType = getMimeType(imageFile.path);
    MediaType? mediaType;
    if (contentType != null) {
      final parts = contentType.split('/');
      if (parts.length == 2) {
        mediaType = MediaType(parts[0], parts[1]);
      }
    }

    req.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: p.basename(imageFile.path),
      contentType: mediaType,
    ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    // 응답 상태 코드 및 본문 로깅
    debugPrint('★★★ uploadProfileImage 응답 상태 코드: ${resp.statusCode}');
    debugPrint('★★★ uploadProfileImage 응답 본문: ${resp.body}');

    if (resp.statusCode != 200) {
      debugPrint('★★★ uploadProfileImage 실패, 응답 본문: ${resp.body}');
      throw Exception('이미지 업로드 실패 (${resp.statusCode})');
    }

    // 성공 시 응답 본문을 파싱하여 originImagePath와 thumbnailImagePath 반환
    try {
      final Map<String, dynamic> json = jsonDecode(resp.body);
      final originImagePath = json['originImagePath'] as String?; // nullable로 받습니다.
      final thumbnailImagePath = json['thumbnailImagePath'] as String?; // nullable로 받습니다.
      if (originImagePath == null) {
        debugPrint('★★★ uploadProfileImage 성공 응답에 originImagePath가 null입니다.');
        throw Exception('업로드 응답에 originImagePath 없음');
      }
      if (thumbnailImagePath == null) {
        debugPrint('★★★ uploadProfileImage 성공 응답에 thumbnailImagePath가 null입니다.');
        throw Exception('업로드 응답에 thumbnailImagePath 없음');
      }
      debugPrint('★★★ uploadProfileImage 성공, 반환된 originImagePath: $originImagePath, thumbnailImagePath: $thumbnailImagePath');
      return originImagePath + ',' + thumbnailImagePath; // originImagePath와 thumbnailImagePath를 쉼표로 구분하여 반환
    } catch (e) {
      debugPrint('★★★ uploadProfileImage 성공 응답 파싱 중 오류: ${e.runtimeType} - $e');
      debugPrint('    파싱하려던 응답 본문: ${resp.body}');
      throw Exception('이미지 업로드 응답 파싱 실패'); // 새로운 예외 발생
    }
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
    // 응답 상태 코드 및 본문 로깅 (성공/실패 여부와 관계없이 항상 출력)
    debugPrint('★★★ updateProfile PUT ${uri.toString()}');
    debugPrint('    Request body: ${jsonEncode(body)}');
    debugPrint('★★★ updateProfile 응답 상태 코드: ${resp.statusCode}');
    debugPrint('★★★ updateProfile 응답 본문: ${resp.body}');

    // 200 상태 코드가 아니면 예외 발생
    if (resp.statusCode != 200) {
      // 실패 응답 본문은 이미 위에서 출력됨
      throw Exception('프로필 업데이트 실패 (${resp.statusCode})');
    }

    // 성공 시 응답 본문을 UserProfile 객체로 변환 및 로깅
    try {
      final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
      final updatedProfile = UserProfile.fromJson(jsonMap);
      debugPrint('★★★ updateProfile 성공, 반환된 UserProfile: $updatedProfile');
      return updatedProfile;
    } catch (e) {
      // JSON 파싱 또는 fromJson 과정에서 오류 발생 시 로그 출력
      debugPrint('★★★ updateProfile 성공 응답 파싱 중 오류: ${e.runtimeType} - $e');
      debugPrint('    파싱하려던 응답 본문: ${resp.body}');
      throw Exception('프로필 업데이트 응답 파싱 실패'); // 새로운 예외 발생시켜 catch 블록으로 전달
    }
  }
}
