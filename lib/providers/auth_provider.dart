import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  int? _userId;
  String? _userEmail;
  String? _userNickname;
  String? _token; // JWT 토큰 저장

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  String? get token => _token;

  AuthProvider() {
    // 초기화 시 자동 로그인 체크
    checkAutoLogin();
  }

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
        _userEmail = userEmail;
        _token = token;
        // userId와 userNickname 로드 및 프로필 확인/생성은 이 메서드에서 처리
        print('자동 로그인 성공, 사용자 정보 및 프로필 로드 시작');
        await loadUserInfoAndProfile(_token!, _userEmail!); // 사용자 정보 및 프로필 로드/생성

      } else {
        _isLoggedIn = false;
        _userId = null;
        _userEmail = null;
        _userNickname = null;
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
        _userEmail = email;
        _token = response['token'];
        // userId와 nickname은 loadUserInfoAndProfile에서 처리

        print('로그인 성공, 사용자 정보 및 프로필 로드 시작');
        // 사용자 정보 및 프로필 로드/생성 메서드 호출
        await loadUserInfoAndProfile(_token!, _userEmail!);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userNickname');
      await prefs.remove('token');
      await prefs.remove('autoLogin');
      
      _isLoggedIn = false;
      _userId = null;
      _userEmail = null;
      _userNickname = null;
      _token = null;
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
             _userNickname = profileResponse['profile']['nickname'];
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
        final userInfoResponse = await AuthService.getUserInfo(_token!, _userEmail);
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
       //    AuthProvider의 _userId, _userEmail, _userNickname 상태가 채워져 있어야 함.
       print('loadUserInfoAndProfile: 사용자 정보 로드 시도');

       if (_userId == null) {
          print('loadUserInfoAndProfile: userId가 null입니다. getUserInfo 시도.');
          // getUserInfo 호출 시 토큰 전달
          final userInfoResponse = await AuthService.getUserInfo(token, email);
           if (userInfoResponse['success'] && userInfoResponse['userId'] != null) {
             _userId = userInfoResponse['userId'];
             _userNickname = userInfoResponse['nickname'];
             _userEmail = userInfoResponse['email'];
             print('loadUserInfoAndProfile: getUserInfo 성공, userId: $_userId, nickname: $_userNickname');

             // SharedPreferences 업데이트
             final prefs = await SharedPreferences.getInstance();
             await prefs.setInt('userId', _userId!);
             if (_userNickname != null) {
               await prefs.setString('userNickname', _userNickname!);
             }
             await prefs.setString('userEmail', _userEmail!); // 이메일도 저장

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
            _userNickname = profileResponse['profile']['nickname'];
            // 필요에 따라 다른 프로필 정보도 저장
            // 예: _userIntroduction = profileResponse['profile']['introduction'];
            print('AuthProvider 프로필 정보 업데이트: nickname=$_userNickname');

            // SharedPreferences 업데이트 (닉네임)
             final prefs = await SharedPreferences.getInstance();
             if (_userNickname != null) {
               await prefs.setString('userNickname', _userNickname!);
             }
         }
       } else if (profileResponse['statusCode'] == 404) {
         print('프로필을 찾을 수 없습니다 (404). 새로 생성합니다.');
         // 프로필이 없으면 새로 생성
         if (_userNickname == null) {
             print('경고: userId는 있지만 nickname이 없어 기본 닉네임으로 프로필 생성 시도');
             // 닉네임이 없는 경우 기본값 사용 또는 에러 처리
             _userNickname = '사용자'; // 임시 기본 닉네임
         }
         // createProfile 호출 시 토큰 전달
         final createProfileResponse = await AuthService.createProfile(_userId!, _userNickname!, token); // userId, nickname, 토큰 사용

         if (createProfileResponse['success']) {
            print('프로필 생성 성공 후 정보 로드');
             if (createProfileResponse['profile'] != null) {
               _userNickname = createProfileResponse['profile']['nickname'];
               print('AuthProvider 프로필 정보 업데이트 (생성 후): nickname=$_userNickname');
               // SharedPreferences 업데이트 (닉네임)
               final prefs = await SharedPreferences.getInstance();
                if (_userNickname != null) {
                 await prefs.setString('userNickname', _userNickname!);
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
}