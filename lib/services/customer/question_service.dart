import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ourlog/models/inquiry.dart';

class QuestionService {
  static const String _baseUrl = 'http://10.100.204.157:8080/ourlog/question';

  // 🔹 문의 등록
  Future<bool> submitInquiry(String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$_baseUrl/inquiry'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title, 'content': content}),
    );

    return response.statusCode == 200;
  }

  // 🔹 문의 수정
  Future<bool> editInquiry(String questionId, String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.put(
      Uri.parse('$_baseUrl/editingInquiry'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'questionId': questionId, 'title': title, 'content': content}),
    );

    return response.statusCode == 200;
  }

  // 🔹 문의 리스트 (내가 작성한 것들)
  Future<List<Inquiry>> fetchInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/my-questions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Inquiry.fromJson(e)).toList();
    } else {
      throw Exception('문의내역 로딩 실패: ${response.statusCode}');
    }
  }

  // 🔹 문의 전체 리스트 (관리자용)
  Future<List<Inquiry>> fetchAllInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$_baseUrl/questionList'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response body: ${response.body}'); // 여기서 응답 데이터 확인


    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return (data['dtoList'] as List).map((e) => Inquiry.fromJson(e)).toList();
    } else {
      throw Exception('전체 문의 목록 로딩 실패: ${response.statusCode}');
    }
  }

  // 🔹 문의 삭제
  Future<bool> deleteInquiry(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('$_baseUrl/deleteQuestion/$questionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
