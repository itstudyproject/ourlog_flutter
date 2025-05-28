import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../models/picture.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'dart:io'; // Import dart:io for File

class PictureService {
  static const String baseUrl = 'http://10.100.204.157:8080/ourlog'; // API 도메인으로 변경 필요

  // 이미지 목록 가져오기
  static Future<List<Picture>> getPictures({int page = 0, int size = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pictures?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Picture.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pictures: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load pictures: $e');
    }
  }

  // 이미지 상세 조회
  static Future<Picture> getPictureById(int pictureId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pictures/$pictureId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode == 200) {
        return Picture.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load picture: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load picture: $e');
    }
  }

  // 새 이미지 업로드 (Multipart)
  static Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
       throw Exception('인증 토큰이 없습니다.');
    }

    // Assuming the upload endpoint is /upload
    final uri = Uri.parse('$baseUrl/upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file', // This should match the backend's expected file parameter name
        imageFile.path,
      ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming backend returns paths like in UploadResultDTO
        if (data is Map && data.containsKey('originImagePath') && data.containsKey('thumbnailImagePath')) {
           return {
             'originImagePath': data['originImagePath'],
             'thumbnailImagePath': data['thumbnailImagePath'],
           };
        } else {
           throw Exception('이미지 업로드 응답 형식이 잘못되었습니다: ${response.body}');
        }
      } else {
        String errorMessage = '이미지 업로드 실패: ${response.statusCode}';
         try {
            final errorData = json.decode(response.body);
            if (errorData is Map && errorData.containsKey('message')) {
               errorMessage = '이미지 업로드 실패: ${errorData['message']}';
            }
         } catch (e) {
            // Ignore parsing error, use default message
         }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('이미지 업로드 중 오류 발생: ${e.toString()}');
    }
  }

  // 이미지 수정
  static Future<Picture> updatePicture(Picture picture) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pictures/${picture.picId}'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
        body: json.encode(picture.toJson()),
      );

      if (response.statusCode == 200) {
        return Picture.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update picture: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update picture: $e');
    }
  }

  // 이미지 삭제
  static Future<void> deletePicture(int pictureId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pictures/$pictureId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete picture: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete picture: $e');
    }
  }

  // 게시글에 연결된 이미지 목록 가져오기
  static Future<List<Picture>> getPicturesByPostId(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pictures/post/$postId'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Picture.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pictures: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load pictures: $e');
    }
  }
} 