import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ourlog/models/answer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnswerService {
  static const String _baseUrl = 'http://10.100.204.124:8080/ourlog';

  // 🔹 답변 작성 또는 수정
  Future<Answer?> createAnswer(String questionId, String contents) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (contents.trim().isEmpty || token.isEmpty) return null;

    final response = await http.post(
      Uri.parse('$_baseUrl/question-answer/$questionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contents': contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Answer.fromJson(data);
    } else {
      print('답변 작성 실패: ${response.body}');
      return null;
    }
  }

  // 🔹 답변 수정
  Future<bool> modifyAnswer(String answerId, String contents) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.put(
      Uri.parse('$_baseUrl/question-answer/$answerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'contents': contents}),
    );
    print('답변 작성 실패: ${response.body}');
    return response.statusCode == 200;
  }

  // 🔹 답변 삭제
  Future<bool> deleteAnswer(String answerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('$_baseUrl/question-answer/$answerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
