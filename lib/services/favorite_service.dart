// lib/services/favorite_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/favorite.dart';

class FavoriteService {
  static const String _baseUrl = 'http://10.100.204.189:8080/ourlog/profile';

  // 1) 북마크 목록 조회
  Future<List<Favorite>> fetchFavorites(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = '$_baseUrl/favorites/$userId';
    final resp = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (resp.statusCode != 200) throw Exception('북마크 조회 실패');
    final List data = jsonDecode(resp.body);
    return data.map((e) => Favorite.fromJson(e)).toList();
  }

  // 2) 북마크 해제
  Future<void> deleteFavorite(int favoriteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final url = '$_baseUrl/favorites/$favoriteId';
    final resp = await http.delete(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (resp.statusCode != 200) throw Exception('북마크 해제 실패');
  }
}