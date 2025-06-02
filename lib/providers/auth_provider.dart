import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';


class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  int? _userId;
  String? _email;
  String? _nickname;
  String? _token; // JWT 토큰 저장

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get userEmail => _email;
  String? get userNickname => _nickname;
  String? get token => _token;

  AuthProvider() {
    // 초기화 시 자동 로그인 체크
    checkAutoLogin();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 토큰 설정
  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }

  // 유저 ID 설정
  void setUserId(int? userId) {
    _userId = userId;
    notifyListeners();
  }

  // 닉네임 설정
  void setNickname(String? nickname) {
    _nickname = nickname;
    notifyListeners();
  }

  /// Google 로그인: 백엔드에 인증 코드 전송 및 리다이렉트 처리
  // Future<Map<String, dynamic>> googleLoginWithCode(String code) async {
  //   // 백엔드 콜백 엔드포인트 URL (쿼리 파라미터로 code 전송)
  //   final url = Uri.parse('http://10.100.204.124:8080/ourlog/google/callback?code=$code');
  //
  //   try {
  //     // 백엔드 콜백 엔드포인트는 GET 요청을 기대합니다.
  //     // 백엔드는 이 요청을 처리한 후, 토큰을 포함한 URL로 프론트엔트를 리다이렉트합니다.
  //     // 따라서 여기서는 직접적인 HTTP 응답을 받기 어렵습니다.
  //     // 실제 앱에서는 이 URL을 브라우저/웹뷰로 열고, 리다이렉트된 최종 URL에서 토큰을 추출해야 합니다.
  //     // 아래 코드는 개념적인 예시이며, 실제 구현은 리다이렉트 처리를 포함해야 합니다.
  //
  //     // 여기서는 백엔드가 리다이렉트하는 대신 응답을 보냈다고 가정하고 작성합니다.
  //     // 실제 백엔드 코드에 맞추려면 이 부분을 리다이렉트 처리 로직으로 대체해야 합니다.
  //     final response = await http.get(url); // GET 요청으로 변경
  //
  //     if (response.statusCode == 200) {
  //       // 백엔드가 성공적으로 처리 후 리다이렉트 대신 응답을 보냈다고 가정
  //       final data = json.decode(response.body);
  //       return {
  //         'success': data['success'],
  //         'token': data['token'],
  //         'userId': data['userId'], // 백엔드 응답에 userId가 있다면 사용
  //         'nickname': data['nickname'], // 백엔드 응답에 nickname이 있다면 사용
  //       };
  //     } else {
  //       // 백엔드에서 오류 응답이 온 경우
  //       return {
  //         'success': false,
  //         'message': '서버 오류: ${response.statusCode}',
  //       };
  //     }
  //   } catch (e) {
  //     debugPrint('Google 로그인 코드 전송 중 오류: $e');
  //     return {
  //       'success': false,
  //       'message': '요청 실패: ${e.toString()}',
  //     };
  //   }
  // }

  // 자동 로그인 체크
  Future<void> checkAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLogin = prefs.getBool('autoLogin') ?? false;
      final token = prefs.getString('token');
      final userEmail = prefs.getString('userEmail');
      // userId와 userNickname은 이제 SharedPreferences에서 직접 읽지 않고
      // loadUserInfoAndProfile에서 관리하도록 변경

      if (autoLogin && token != null && userEmail != null) {
        _isLoggedIn = true;
        _email = userEmail;
        _token = token;
        // userId와 userNickname 로드 및 프로필 확인/생성은 이 메서드에서 처리
        print('자동 로그인 성공, 사용자 정보 및 프로필 로드 시작');
        await loadUserInfoAndProfile(_token!, _email!); // 사용자 정보 및 프로필 로드/생성

      } else {
        _isLoggedIn = false;
        _userId = null;
        _email = null;
        _nickname = null;
        _token = null;
      }
    } catch (e) {
      print('자동 로그인 처리 중 오류 발생: $e');
      _errorMessage = '자동 로그인 처리 중 오류가 발생했습니다.';
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인
  Future<bool> login(String email, String password, {bool autoLogin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = "이메일과 비밀번호를 모두 입력해주세요.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('로그인 요청 시작: $email');
      final response = await AuthService.login(email, password);
      print('로그인 응답: $response');
      
      if (response['success']) {
        // 로그인 성공 정보 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('token', response['token']);
        await prefs.setBool('autoLogin', autoLogin);

        _isLoggedIn = true;
        _email = email;
        _token = response['token'];
        // userId와 nickname은 loadUserInfoAndProfile에서 처리

        print('로그인 성공, 사용자 정보 및 프로필 로드 시작');
        // 사용자 정보 및 프로필 로드/생성 메서드 호출
        await loadUserInfoAndProfile(_token!, _email!);

        // React 코드처럼 로그인 성공 시 사용자 정보 출력
        print('✅ OurLog 로그인 성공:');
        print('   Email: $_email');
        print('   UserId: $_userId');
        print('   Nickname: $_nickname');

        _isLoading = false;
        // loadUserInfoAndProfile에서 notifyListeners를 호출하므로 여기서 다시 호출할 필요 없음
        // notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? "로그인에 실패했습니다.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('로그인 처리 중 예외 발생: $e');
      _errorMessage = "로그인 처리 중 오류가 발생했습니다.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Google Sign-In 로그아웃 추가
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print('Google Sign-In 로그아웃 성공');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userNickname');
      await prefs.remove('token');
      await prefs.remove('autoLogin');
      
      _isLoggedIn = false;
      _userId = null;
      _email = null;
      _nickname = null;
      _token = null;

      print('앱 로그아웃 성공');

    } catch (e) {
      _errorMessage = '로그아웃 처리 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 회원가입
  Future<bool> register(String email, String password, String passwordConfirm, String name, String nickname, String mobile, bool fromSocial) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.register(email, password, passwordConfirm, name, nickname, mobile, fromSocial);
      
      if (response['success'] && response['userId'] != null) {
        final userId = response['userId'];
        print('회원가입 성공, userId: $userId');

        // 회원가입 성공 후 프로필 자동 생성 시도
        // createProfile 호출 시 토큰 전달 (회원가입 직후에는 _token이 null일 수 있음)
        final profileResponse = await AuthService.createProfile(userId, nickname, _token); 

        if (profileResponse['success']) {
           print('프로필 자동 생성 성공');
           // 생성된 프로필 정보를 AuthProvider 상태에 저장 (선택 사항)
           if (profileResponse['profile'] != null) {
             _nickname = profileResponse['profile']['nickname'];
             // 필요에 따라 다른 프로필 정보도 저장
             // 예: _userIntroduction = profileResponse['profile']['introduction'];
           }
        } else {
           print('⚠️ 경고: 프로필 자동 생성 실패: ${profileResponse['message']}');
           // 프로필 생성 실패 시 에러 메시지 설정 (회원가입 자체는 성공)
           _errorMessage = profileResponse['message'] ?? '프로필 생성에 실패했습니다.';
           // notifyListeners(); // 상태 업데이트 (필요 시 주석 해제)
        }

        _isLoading = false;
        notifyListeners();
        return true; // 회원가입 성공
      } else {
        _errorMessage = response['message'] ?? '회원가입에 실패했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '회원가입 처리 중 오류가 발생했습니다.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 회원탈퇴
  Future<bool> deleteAccount() async {
    // 로그인 상태 확인
    if (!_isLoggedIn || _token == null) {
      _errorMessage = '로그인이 필요합니다.';
      notifyListeners();
      return false;
    }

    // userId 확인
    if (_userId == null) {
      print('⚠️ 경고: 회원탈퇴 시도 - 로그인 상태이지만 userId가 null입니다.');
      
      // 추가 요청으로 userId 획득 시도
      try {
        final userInfoResponse = await AuthService.getUserInfo(_token!, _email);
        if (userInfoResponse['success'] && userInfoResponse['userId'] != null) {
          _userId = userInfoResponse['userId'];
          print('회원탈퇴를 위해 사용자 정보 API에서 획득한 userId: $_userId');
          
          // SharedPreferences 업데이트
          final prefs = await SharedPreferences.getInstance();
          if (_userId != null) {
            await prefs.setInt('userId', _userId!);
          }
        } else {
          print('회원탈퇴를 위한 사용자 정보 획득 실패: ${userInfoResponse['message']}');
          _errorMessage = '사용자 정보를 가져올 수 없습니다.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        print('회원탈퇴 전 사용자 정보 획득 중 오류: $e');
        _errorMessage = '사용자 정보를 확인하는 중 오류가 발생했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
    
    // userId가 여전히 null인 경우
    if (_userId == null) {
      _errorMessage = '사용자 ID를 확인할 수 없습니다.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // userId 타입 확인 및 정수 변환 
      final int userId = _userId!;
      print('회원탈퇴 시도: userId=$userId (${userId.runtimeType})');
      
      if (userId <= 0) {
        print('⚠️ 경고: 유효하지 않은 userId입니다: $userId');
        _errorMessage = '유효하지 않은 사용자 ID입니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // 토큰 검사
      if (_token!.isEmpty) {
        print('⚠️ 경고: 토큰이 비어있습니다.');
        _errorMessage = '인증 정보가 유효하지 않습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      // 토큰 출력 (디버깅용)
      print('사용할 토큰: ${_token!.substring(0, _token!.length > 30 ? 30 : _token!.length)}...');
      
      // 삭제 요청
      final response = await AuthService.deleteUser(userId, _token!);
      
      if (response['success']) {
        await logout(); // 로그아웃 처리
        return true;
      } else {
        _errorMessage = response['message'] ?? '회원탈퇴에 실패했습니다.';
        
        // 403 오류인 경우 토큰 갱신을 권장하는 메시지 추가
        if (_errorMessage!.contains('권한이 없습니다') || _errorMessage!.contains('403')) {
          _errorMessage = '${_errorMessage!} 다시 로그인 후 시도해주세요.';
        }
        
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '회원탈퇴 처리 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 사용자 정보를 로드하고 프로필을 확인/생성하는 메서드 (로그인 성공 시 호출)
  Future<void> loadUserInfoAndProfile(String token, String email) async {
     _isLoading = true;
     _errorMessage = null;
     notifyListeners();

     try {
       // 1. 사용자 기본 정보 로드 (userId, email, nickname 등)
       //    로그인 시 userId를 토큰에서 추출하거나 getUserInfo로 가져온다고 가정
       //    AuthProvider의 _userId, _email, _nickname 상태가 채워져 있어야 함.
       print('loadUserInfoAndProfile: 사용자 정보 로드 시도');

       if (_userId == null) {
          print('loadUserInfoAndProfile: userId가 null입니다. getUserInfo 시도.');
          // getUserInfo 호출 시 토큰 전달
          final userInfoResponse = await AuthService.getUserInfo(token, email);
           if (userInfoResponse['success'] && userInfoResponse['userId'] != null) {
             _userId = userInfoResponse['userId'];
             _nickname = userInfoResponse['nickname'];
             _email = userInfoResponse['email'];
             print('loadUserInfoAndProfile: getUserInfo 성공, userId: $_userId, nickname: $_nickname');

             // SharedPreferences 업데이트
             final prefs = await SharedPreferences.getInstance();
             await prefs.setInt('userId', _userId!);
             if (_nickname != null) {
               await prefs.setString('userNickname', _nickname!);
             }
             await prefs.setString('userEmail', _email!); // 이메일도 저장

           } else {
             print('loadUserInfoAndProfile: getUserInfo 실패: ${userInfoResponse['message']}');
             _errorMessage = userInfoResponse['message'] ?? '사용자 정보를 가져오는데 실패했습니다.';
             _isLoading = false;
             notifyListeners();
             return; // 사용자 정보 없으면 프로필 로드/생성 불가
           }
       }

       // userId가 확보되었으므로 프로필 로드 시도
       print('loadUserInfoAndProfile: userId 확보 ($_userId), 프로필 로드 시도');
       // fetchProfile 호출 시 토큰 전달
       final profileResponse = await AuthService.fetchProfile(_userId!, token); // userId와 토큰 전달

       if (profileResponse['success']) {
         print('프로필 로드 성공');
         // 프로필 정보 업데이트
         if (profileResponse['profile'] != null) {
            _nickname = profileResponse['profile']['nickname'];
            // 필요에 따라 다른 프로필 정보도 저장
            // 예: _userIntroduction = profileResponse['profile']['introduction'];
            print('AuthProvider 프로필 정보 업데이트: nickname=$_nickname');

            // SharedPreferences 업데이트 (닉네임)
             final prefs = await SharedPreferences.getInstance();
             if (_nickname != null) {
               await prefs.setString('userNickname', _nickname!);
             }
         }
       } else if (profileResponse['statusCode'] == 404) {
         print('프로필을 찾을 수 없습니다 (404). 새로 생성합니다.');
         // 프로필이 없으면 새로 생성
         if (_nickname == null) {
             print('경고: userId는 있지만 nickname이 없어 기본 닉네임으로 프로필 생성 시도');
             // 닉네임이 없는 경우 기본값 사용 또는 에러 처리
             _nickname = '사용자'; // 임시 기본 닉네임
         }
         // createProfile 호출 시 토큰 전달
         final createProfileResponse = await AuthService.createProfile(_userId!, _nickname!, token); // userId, nickname, 토큰 사용

         if (createProfileResponse['success']) {
            print('프로필 생성 성공 후 정보 로드');
             if (createProfileResponse['profile'] != null) {
               _nickname = createProfileResponse['profile']['nickname'];
               print('AuthProvider 프로필 정보 업데이트 (생성 후): nickname=$_nickname');
               // SharedPreferences 업데이트 (닉네임)
               final prefs = await SharedPreferences.getInstance();
                if (_nickname != null) {
                 await prefs.setString('userNickname', _nickname!);
               }
             }
         } else {
            print('⚠️ 경고: 프로필 생성 실패 (로그인 후): ${createProfileResponse['message']}');
            _errorMessage = createProfileResponse['message'] ?? '프로필 생성에 실패했습니다.';
         }
       } else {
          // 프로필 로드 실패 (404 외 다른 오류)
          print('⚠️ 경고: 프로필 로드 실패 (로그인 후): ${profileResponse['message']}');
          _errorMessage = profileResponse['message'] ?? '프로필 로드에 실패했습니다.';
       }

     } catch (e) {
       print('사용자 정보 및 프로필 로드/생성 중 예외 발생: $e');
       _errorMessage = '사용자 정보 및 프로필 로드 중 오류가 발생했습니다.';
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  static Future<bool> checkIsAdmin() async {
    try {
      print('checkIsAdmin 호출됨');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('http://10.100.204.124:8080/ourlog/user/check-admin'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
      if (token == null) return false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Check Admin Response: $data"); // 👈 추가

        return data['isAdmin'] == true;
      } else {
        print("Admin check failed: ${response.statusCode}, ${response.body}"); // 👈 추가

        return false;
      }
    } catch (e, st) {
      print('checkIsAdmin 예외 발생: $e\n$st');
      return false;
    }
  }

  // Google 로그인 처리
  Future<Map<String, dynamic>> googleLogin(String googleIdToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  
    try {
      // TODO: 백엔드 Google 로그인 엔드포인트 (예: /auth/google-login) 호출
      // React 코드의 performSocialLogin 함수 참고하여 구현
      // HTTP 클라이언트 (http 패키지 사용)
  
      final url = Uri.parse('http://10.100.204.124:8080/ourlog/user/flutter/googleLogin'); // 백엔드 엔드포인트 URL
  
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleIdToken}), // 백엔드가 기대하는 요청 바디 형식에 맞게 수정
      );
  
      if (response.statusCode == 200) {
        // 백엔드 인증 성공, JWT 토큰 및 사용자 정보 수신
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? token = responseData['token'];
        final int? userId = responseData['userId']; // 백엔드 응답에서 userId 키 확인
        final String? nickname = responseData['nickname']; // 백엔드 응답에서 nickname 키 확인
        final String? email = responseData['email']; // 백엔드 응답에서 email 키 확인
  
        if (token != null && userId != null && (nickname != null || email != null)) { // nickname 또는 email이 있으면 진행
          _token = token;
          _userId = userId;
          _email = email; // Google 로그인 이메일 저장
          _nickname = nickname; // 백엔드에서 받은 닉네임 저장
          _isLoggedIn = true;
  
          // 토큰 영구 저장
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          // 사용자 ID, 닉네임, 이메일도 저장
          await prefs.setInt('userId', userId);
           if (_nickname != null) {
             await prefs.setString('userNickname', _nickname!);
           }
           if (_email != null) {
             await prefs.setString('userEmail', _email!); // 이메일 저장
           }


          _errorMessage = null; // 성공 시 오류 메시지 초기화

          // 사용자 정보 및 프로필 로드/생성 메서드 호출 (일반 로그인과 동일)
          // _email이 null일 가능성이 있으므로 안전하게 호출
          if (_email != null) {
             print('Google 로그인 성공, 사용자 정보 및 프로필 로드 시작');
             await loadUserInfoAndProfile(_token!, _email!); // 토큰과 이메일 전달
          } else {
             // email 정보가 백엔드 응답에 없는 경우 프로필 로드/생성 로직만 직접 호출.
             // 하지만 loadUserInfoAndProfile 내의 getUserInfo 호출이 email을 요구하므로 이 방식도 문제될 수 있음.
             // 가장 좋은 방법은 백엔드에서 email을 함께 내려주거나, loadUserInfoAndProfile을 개선하는 것입니다.
             print('⚠️ 경고: Google 로그인 응답에 이메일이 없습니다. 프로필 로드/생성 로직을 건너뛰거나 수정해야 합니다.');
             // 일단 notifyListeners만 호출하여 UI 상태 업데이트
             notifyListeners();
          }


          // loadUserInfoAndProfile 내에서 notifyListeners를 호출하므로 여기서는 필요에 따라 제거하거나 유지
          // notifyListeners(); // UI 상태 업데이트

          // React 코드처럼 로그인 성공 시 사용자 정보 출력 (디버깅용)
           print('✅ OurLog Google 로그인 성공:');
           print('   Email: $_email');
           print('   UserId: $_userId');
           print('   Nickname: $_nickname');


          return {'success': true, 'token': token, 'userId': userId, 'nickname': nickname, 'email': email}; // email도 포함하여 반환
        } else {
          // 응답 형식 오류 또는 필수 정보 누락
          _errorMessage = '백엔드 Google 인증 응답 형식 오류 또는 필수 정보 누락';
          notifyListeners();
          return {'success': false, 'message': _errorMessage};
        }
      } else {
        // 백엔드 인증 실패
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? '백엔드 Google 인증 실패 (상태 코드: ${response.statusCode})';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }
  
    } catch (e) {
      _errorMessage = '백엔드 Google 인증 요청 중 오류 발생: ${e.toString()}';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}