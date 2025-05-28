// lib/services/favorite_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/favorite.dart';

class FavoriteService {
  static const String _baseUrl = 'http://10.100.204.189:8080/ourlog';

  /// 1) 북마크 목록 조회
  ///
  /// HTTP 에러 시 Exception을 던지고,
  /// 빈 리스트일 때는 그냥 빈 리스트를 반환합니다.
  Future<List<Favorite>> fetchFavorites(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$_baseUrl/profile/favorites/$userId');
    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // HTTP 상태 코드가 200이 아니면 실패로 간주
    if (resp.statusCode != 200) {
      throw Exception('북마크 조회 실패 (${resp.statusCode})');
    }

    // JSON 파싱
    final List<dynamic> data = jsonDecode(resp.body);

    // 빈 리스트여도 예외를 던지지 않고 그대로 반환
    return data.map((e) => Favorite.fromJson(e)).toList();
  }

  /// 2) 북마크 해제
  ///
  /// 삭제 API 호출 후, 상태 코드가 200이 아니면 Exception을 던집니다.
  Future<void> deleteFavorite(int favoriteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$_baseUrl/profile/favorites/$favoriteId');
    final resp = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('북마크 해제 실패 (${resp.statusCode})');
    }
  }
}