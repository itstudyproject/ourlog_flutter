// lib/services/trade_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_response.dart';
import '../models/trade.dart';

class TradeService {
  // NOTE: make sure this matches your @RequestMapping on the backend,
  // which was "/profile" + "/purchases/{userId}" etc.
  static const String _baseUrl = 'http://10.100.204.47:8080/ourlog/profile';

  /// 구매
  Future<PurchaseResponse> fetchPurchases(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = '$_baseUrl/purchases/$userId';
    print('▶▶ GET $url');
    print('    Authorization: Bearer $token');

    final resp = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀◀ ${resp.statusCode} ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('구매/입찰 목록 조회 실패 (${resp.statusCode})');
    }

    final Map<String, dynamic> jsonMap = jsonDecode(resp.body);
    return PurchaseResponse.fromJson(jsonMap);
  }

  /// 판매
  Future<List<Trade>> fetchSales(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = '$_baseUrl/sales/$userId';
    print('▶▶ GET $url');
    print('    Authorization: Bearer $token');

    final resp = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print('◀◀ ${resp.statusCode} ${resp.body}');
    if (resp.statusCode != 200) {
      throw Exception('판매 목록 조회 실패 (${resp.statusCode})');
    }

    final List<dynamic> list = jsonDecode(resp.body);
    return list.map((json) => Trade.fromJson(json)).toList();
  }
}