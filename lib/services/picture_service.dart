import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/picture.dart';

class PictureService {
  static const String baseUrl = 'http://your-api-domain.com/api'; // API 도메인으로 변경 필요

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

  // 새 이미지 업로드
  static Future<Picture> uploadPicture(Picture picture) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pictures'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // 인증이 필요한 경우
        },
        body: json.encode(picture.toJson()),
      );

      if (response.statusCode == 201) {
        return Picture.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to upload picture: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload picture: $e');
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