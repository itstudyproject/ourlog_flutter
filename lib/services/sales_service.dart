import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sale.dart'; // Sale 모델 위치에 맞게 경로 조정

class SalesService {
  final String _baseUrl = 'http://10.100.204.189:8080/ourlog';

  Future<List<Sale>> fetchSales(int userId, String token) async {
    final uri = Uri.parse('$_baseUrl/profile/sales/$userId');
    print('▶ SalesService: GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('▶ SalesService: 응답 코드 = ${response.statusCode}');
    print('▶ SalesService: 응답 본문 = ${response.body}');

    if (response.statusCode == 200) {
      // 1) JSON을 디코드해서 dynamic 타입으로 저장
      final decoded = json.decode(response.body);
      print('▶ SalesService: json.decode(...) 결과 타입 = ${decoded.runtimeType}');

      // 2) decoded가 배열(List<dynamic>) 형태라면, 각 요소를 Sale.fromJson()으로 변환
      if (decoded is List) {
        return decoded
            .map((item) => Sale.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 3) 혹시 “{ "sales": [ ... ] }”처럼 객체 안에 배열이 있는 구조라면
      if (decoded is Map<String, dynamic> && decoded['sales'] is List) {
        final List<dynamic> arr = decoded['sales'] as List<dynamic>;
        return arr
            .map((item) => Sale.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 4) 위 두 경우가 아니라면 예외 던지기
      throw Exception('예상치 못한 JSON 구조입니다: ${decoded.runtimeType}');
    } else {
      throw Exception('판매 목록 불러오기 실패: ${response.statusCode}');
    }
  }
}
