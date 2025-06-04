// lib/services/picture_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/picture.dart';

class PictureService {
  // 실제 사용하는 IP/포트를 맞춰주세요.
  static const String _baseUrl = 'http://10.100.204.157:8080/ourlog';

  /// 이미지 목록 가져오기 (예시)
  static Future<List<Picture>> getPictures({int page = 0, int size = 10}) async {
    final uri = Uri.parse('$_baseUrl/pictures?page=$page&size=$size');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((e) => Picture.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('이미지 목록 가져오기 실패: ${response.statusCode}');
    }
  }

  /// 이미지 상세 조회 (예시)
  static Future<Picture> getPictureById(int pictureId) async {
    final uri = Uri.parse('$_baseUrl/pictures/$pictureId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return Picture.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('이미지 상세 조회 실패: ${response.statusCode}');
    }
  }

  /// 새 이미지 업로드 (Multipart)
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    // 1) SharedPreferences 에 저장된 토큰 가져오기
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      throw Exception('인증 토큰이 없습니다.');
    }

    // 2) MultipartRequest 준비
    final uri = Uri.parse('$_baseUrl/picture/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'multipart/form-data';

    // ★ 백엔드가 받는 필드 이름을 꼭 API 명세에 맞춰주세요.
    request.files.add(
      await http.MultipartFile.fromPath(
        'files', // 실제 API가 기대하는 키로 변경
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final bodyDecoded = json.decode(response.body);

        /// 3) 응답이 Map 형태인지, List 형태인지 체크
        Map<String, dynamic> dataMap;
        if (bodyDecoded is Map<String, dynamic>) {
          dataMap = bodyDecoded;
        } else if (bodyDecoded is List &&
            bodyDecoded.isNotEmpty &&
            bodyDecoded[0] is Map<String, dynamic>) {
          dataMap = bodyDecoded[0] as Map<String, dynamic>;
        } else {
          throw Exception('이미지 업로드 응답 형식이 잘못되었습니다: ${response.body}');
        }

        // 4) 필요한 키가 모두 들어있는지 확인
        if (!dataMap.containsKey('originImagePath') ||
            !dataMap.containsKey('thumbnailImagePath')) {
          throw Exception('이미지 업로드 응답에 필수 키가 없습니다: ${response.body}');
        }

        // 5) 필요한 키만 뽑아서 Map으로 리턴
        return {
          'picId': dataMap['picId'],
          'uuid': dataMap['uuid'],
          'picName': dataMap['picName'],
          'path': dataMap['path'],
          'picDescribe': dataMap['picDescribe'],
          'downloads': dataMap['downloads'],
          'tag': dataMap['tag'],
          'originImagePath': dataMap['originImagePath'],
          'thumbnailImagePath': dataMap['thumbnailImagePath'],
          'resizedImagePath': dataMap['resizedImagePath'],
          'ownerId': dataMap['ownerId'],
          'postId': dataMap['postId'],
        };
      } else {
        // ■ Status 코드가 200이 아닌 경우: 서버 오류 메시지가 있으면 사용
        String errorMessage = '이미지 업로드 실패: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            errorMessage = '이미지 업로드 실패: ${errorData['message']}';
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 오류 발생: ${e.toString()}');
    }
  }

  /// 이미지 수정 (예시)
  static Future<Picture> updatePicture(Picture picture) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      throw Exception('인증 토큰이 없습니다.');
    }

    final uri = Uri.parse('$_baseUrl/picture/${picture.picId}');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(picture.toJson()),
    );

    if (response.statusCode == 200) {
      return Picture.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('이미지 수정 실패: ${response.statusCode}');
    }
  }

  /// 이미지 삭제
  static Future<void> deletePicture(int pictureId) async {
    // SharedPreferences에서 토큰 꺼내기
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      throw Exception('인증 토큰이 없습니다.');
    }

    // ❗ 아래 URI가 반드시 "…/ourlog/picture/{picId}" 이어야 합니다.
    final uri = Uri.parse('$_baseUrl/picture/$pictureId');

    final response = await http.delete(
      uri,  // ← 이 uri 변수를 그대로 사용해야 합니다.
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('이미지 삭제 실패 (status: ${response.statusCode})');
    }
  }

  /// 특정 게시글에 연결된 이미지 목록 가져오기
  static Future<List<Picture>> getPicturesByPostId(int postId) async {
    final uri = Uri.parse('$_baseUrl/pictures/post/$postId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((e) => Picture.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('게시글 이미지 목록 가져오기 실패: ${response.statusCode}');
    }
  }
}