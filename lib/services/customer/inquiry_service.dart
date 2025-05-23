import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/models/inquiry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InquiryService {
  static const String _baseUrl = 'http://10.100.204.54:8080/ourlog/question';

  // 문의 등록
  Future<bool> submitInquiry(String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = '$_baseUrl/inquiry';

    final body = {
      'title': title,
      'content': content,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  // 문의 수정
  Future<bool> editInquiry(String questionId, String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = '$_baseUrl/editingInquiry';

    final body = {
      'questionId': questionId,
      'title': title,
      'content': content,
    };

    final response = await http.put(  // <-- 여기 수정!
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }


  // 문의내역 리스트 가져오기
  Future<List<Inquiry>> fetchInquiries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final url = '$_baseUrl/my-questions';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Inquiry.fromJson(json)).toList();
    } else {
      throw Exception('문의내역을 불러오는 데 실패했습니다. 상태코드: ${response.statusCode}');
    }
  }

  // 문의 삭제
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
