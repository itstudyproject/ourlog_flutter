import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = 'http://10.100.204.124:8080/ourlog';
  
  // JWT 토큰으로 로그인
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = '$_baseUrl/auth/login?email=$email&password=$password';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        // JWT 토큰을 응답으로 받음
        final token = response.body;
        
        // 토큰이 유효한지 확인 (간단한 검증)
        if (token.isNotEmpty && !token.startsWith('{"code"')) {
          // JWT 토큰에서 사용자 정보 추출 시도 (토큰 페이로드 파싱)
          try {
            final userId = _extractUserIdFromToken(token);
            final nickname = _extractNicknameFromToken(token);
            
            return {
              'success': true,
              'token': token,
              'email': email,
              'userId': userId,
              'nickname': nickname,
            };
          } catch (e) {
            // 토큰 파싱 실패 시 추가 요청으로 사용자 정보 가져오기
            return {
              'success': true,
              'token': token,
              'email': email,
              // userId 값을 못 얻었을 경우 null로 전달하고 후속 처리 필요
            };
          }
        }
      }
      
      return {'success': false, 'message': '로그인에 실패했습니다.'};
    } catch (e) {
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  // JWT 토큰에서 userId 추출 (JWT 구조에 따라 수정 필요)
  static int? _extractUserIdFromToken(String token) {
    try {
      // JWT 구조: header.payload.signature
      final parts = token.split('.');
      print('JWT 토큰 분리: ${parts.length} 부분');
      if (parts.length != 3) {
        print('JWT 토큰 형식이 잘못됨: 3개 부분이 아님');
        return null;
      }

      // Base64 디코딩 (패딩 처리)
      String normalizedPayload = parts[1];
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      
      // url-safe base64 문자 치환
      normalizedPayload = normalizedPayload.replaceAll('-', '+').replaceAll('_', '/');
      print('JWT 페이로드 정규화 완료');

      // 페이로드 디코딩
      final payloadBytes = base64Decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);
      final payload = jsonDecode(payloadString);
      print('JWT 페이로드 디코딩 완료: $payload');

      // 서버 JWT 구조에 맞게 필드명 확인 및 수정
      print('JWT 페이로드 키: ${payload.keys.toList()}');
      
      // 여러 가능한 키 이름 확인
      var userIdValue = payload['userId'];
      if (userIdValue == null) {
        userIdValue = payload['sub'];
        print('userId 없음, sub 사용: $userIdValue');
        
        // sub 값이 이메일인 경우, 이 이메일로 /user/get API를 호출해야 함
        if (userIdValue is String && userIdValue.contains('@')) {
          print('JWT의 sub 값이 이메일임: $userIdValue');
          return null; // 이메일을 userId로 사용할 수 없으므로 null 반환
        }
      }
      if (userIdValue == null) {
        userIdValue = payload['id'];
        print('userId와 sub 없음, id 사용: $userIdValue');
      }
      
      if (userIdValue == null) {
        print('JWT에서 userId 추출 실패: 적절한 키를 찾을 수 없음');
        return null;
      }
      
      if (userIdValue is String) {
        final parsedId = int.tryParse(userIdValue);
        print('String userId를 int로 변환: $userIdValue -> $parsedId');
        return parsedId;
      }
      
      if (userIdValue is int) {
        print('userId는 이미 int 타입: $userIdValue');
        return userIdValue;
      }
      
      print('지원되지 않는 userId 타입: ${userIdValue.runtimeType}');
      return null;
    } catch (e) {
      print('JWT 파싱 오류: $e');
      return null;
    }
  }

  // JWT 토큰에서 nickname 추출 (JWT 구조에 따라 수정 필요)
  static String? _extractNicknameFromToken(String token) {
    try {
      // JWT 구조: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Base64 디코딩 (패딩 처리)
      String normalizedPayload = parts[1];
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }
      
      // url-safe base64 문자 치환
      normalizedPayload = normalizedPayload.replaceAll('-', '+').replaceAll('_', '/');

      // 페이로드 디코딩
      final payloadBytes = base64Decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);
      final payload = jsonDecode(payloadString);

      // 서버 JWT 구조에 맞게 필드명 수정 필요 (일반적으로 'nickname' 등)
      return payload['nickname'] as String?;
    } catch (e) {
      print('JWT 파싱 오류: $e');
      return null;
    }
  }

  // 사용자 정보 가져오기 (토큰에서 userId를 추출할 수 없는 경우 사용)
  static Future<Map<String, dynamic>> getUserInfo(String token, [String? email]) async {
    try {
      // 이메일 정보가 있으면 쿼리 파라미터로 추가
      final endpoint = email != null ? '/user/get?email=$email' : '/user/get';
      print('사용자 정보 요청 시작: $_baseUrl$endpoint, 토큰: ${token.substring(0, 20)}..., 이메일: $email');
      
      final response = await authenticatedGet(endpoint, token);
      
      print('사용자 정보 응답 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('사용자 정보 응답이 비어있습니다');
          return {'success': false, 'message': '사용자 정보 응답이 비어있습니다'};
        }
        
        try {
          final data = jsonDecode(response.body);
          print('사용자 정보 파싱 성공: $data');
          
          final userId = data['userId'] ?? data['id'];
          if (userId == null) {
            print('사용자 정보에 userId 필드가 없습니다: ${data.keys.toList()}');
            return {'success': false, 'message': '사용자 ID를 찾을 수 없습니다'};
          }
          
          return {
            'success': true,
            'userId': userId,
            'email': data['email'],
            'nickname': data['nickname'],
            // 필요한 다른 사용자 정보
          };
        } catch (parseError) {
          print('응답 JSON 파싱 오류: $parseError');
          return {'success': false, 'message': '응답 데이터 파싱에 실패했습니다: $parseError'};
        }
      }
      
      print('사용자 정보 가져오기 실패: ${response.statusCode}');
      return {'success': false, 'message': '사용자 정보를 가져오는데 실패했습니다. (상태 코드: ${response.statusCode})'};
    } catch (e) {
      print('사용자 정보 요청 오류: $e');
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  // 회원가입
  static Future<Map<String, dynamic>> register(String email, String password, String name, String nickname, String mobile, bool fromSocial) async {
    final url = '$_baseUrl/user/register';
    
    try {
      print('회원가입 요청 시작: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'name': name,
          'nickname': nickname,
          'mobile': mobile,
          'fromSocial': fromSocial,
          // 필요한 다른 UserDTO 필드들도 여기에 추가
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('회원가입 요청 타임아웃');
          return http.Response('{"message": "서버 응답 시간이 초과되었습니다."}', 408);
        },
      );
      
      print('회원가입 응답 상태 코드: ${response.statusCode}, 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        // 성공 시 서버에서 반환된 userId 반환
        if (response.body.isEmpty) {
          print('회원가입 응답이 비어있습니다');
          return {'success': false, 'message': '서버 응답이 비어있습니다. 관리자에게 문의하세요.'};
        }
        
        final userId = int.tryParse(response.body);
        if (userId != null) {
          return {'success': true, 'userId': userId};
        }
      }
      
      // 응답 내용을 디버깅하여 오류 메시지 설정
      try {
        if (response.body.isEmpty) {
          print('회원가입 실패 응답이 비어있습니다');
          return {'success': false, 'message': '서버 응답이 비어있습니다. 서버 관리자에게 문의하세요.'};
        }
        
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message'] ?? '회원가입에 실패했습니다.'};
      } catch (decodeError) {
        print('응답 파싱 오류: $decodeError, 응답: ${response.body}, 상태 코드: ${response.statusCode}');
        return {'success': false, 'message': '회원가입에 실패했습니다. (응답: ${response.body})'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  // 회원탈퇴 (Bearer 토큰 인증 사용)
  static Future<Map<String, dynamic>> deleteUser(int userId, String token) async {
    // 회원탈퇴 시 서버 엔드포인트 URL 수정 (이메일을 이용하는 방식으로 변경)
    final url = '$_baseUrl/user/delete/$userId';
    
    try {
      // 토큰에 Bearer 접두어 확인 및 추가
      String authToken = token;
      if (!token.startsWith('Bearer ')) {
        authToken = 'Bearer $token';
      }
      
      print('회원탈퇴 요청 시작: $url, userId: $userId');
      print('인증 토큰: ${authToken.substring(0, authToken.length > 30 ? 30 : authToken.length)}...');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': authToken,
      };
      
      // 전체 헤더 정보 디버깅 출력
      print('요청 헤더:');
      headers.forEach((key, value) {
        print('  $key: ${value.length > 30 ? value.substring(0, 30) + "..." : value}');
      });
      
      // 모든 응답 내용 로깅하기 위한 세부 요청 과정
      try {
        final request = http.Request('DELETE', Uri.parse(url));
        request.headers.addAll(headers);
        
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        print('회원탈퇴 응답 상태 코드: ${response.statusCode}');
        print('회원탈퇴 응답 헤더: ${response.headers}');
        print('회원탈퇴 응답 본문: ${response.body}');
        
        if (response.statusCode == 200) {
          return {'success': true};
        } else if (response.statusCode == 403) {
          print('접근 권한 오류 (403): 인증 토큰이 유효하지 않거나 권한이 없습니다');
          return {'success': false, 'message': '회원탈퇴 권한이 없습니다. 인증 정보를 확인해주세요.'};
        }
        
        // 에러 응답 상세 파싱
        try {
          final errorData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
          final errorMessage = errorData != null && errorData['message'] != null 
              ? errorData['message'] 
              : '회원탈퇴에 실패했습니다. (상태 코드: ${response.statusCode})';
          print('회원탈퇴 실패: $errorMessage');
          return {'success': false, 'message': errorMessage};
        } catch (e) {
          print('회원탈퇴 오류 응답 파싱 실패: $e');
          return {'success': false, 'message': '회원탈퇴에 실패했습니다. (상태 코드: ${response.statusCode})'};
        }
      } catch (requestError) {
        print('회원탈퇴 요청 처리 오류: $requestError');
        return {'success': false, 'message': '회원탈퇴 요청 처리 중 오류가 발생했습니다: $requestError'};
      }
    } catch (e) {
      print('회원탈퇴 요청 오류: $e');
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  // JWT 토큰을 사용한 API 요청 헬퍼 메서드
  static Future<http.Response> authenticatedGet(String path, String token) async {
    String authToken = token;
    if (!token.startsWith('Bearer ')) {
      authToken = 'Bearer $token';
    }
    
    print('API 요청: GET $_baseUrl$path');
    print('인증 헤더: ${authToken.substring(0, authToken.length > 30 ? 30 : authToken.length)}...');
    
    return http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken,
      },
    );
  }

  static Future<http.Response> authenticatedPost(String path, String token, dynamic body) async {
    String authToken = token;
    if (!token.startsWith('Bearer ')) {
      authToken = 'Bearer $token';
    }
    
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken,
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> authenticatedDelete(String path, String token) async {
    String authToken = token;
    if (!token.startsWith('Bearer ')) {
      authToken = 'Bearer $token';
    }
    
    return http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authToken,
      },
    );
  }
}