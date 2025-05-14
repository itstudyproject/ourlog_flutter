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
      final userId = prefs.getInt('userId');
      final userEmail = prefs.getString('userEmail');
      final userNickname = prefs.getString('userNickname');

      if (autoLogin && token != null && userId != null && userEmail != null) {
        _isLoggedIn = true;
        _userId = userId;
        _userEmail = userEmail;
        _userNickname = userNickname;
        _token = token;
      } else {
        _isLoggedIn = false;
        _userId = null;
        _userEmail = null;
        _userNickname = null;
        _token = null;
      }
    } catch (e) {
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
        // 로그인 정보 저장
        final prefs = await SharedPreferences.getInstance();
        
        // userId를 response에서 가져옴
        final userId = response['userId'];
        final nickname = response['nickname'];
        
        print('토큰에서 추출한 userId: $userId, nickname: $nickname');
        
        // userId가 null인 경우 추가 요청으로 사용자 정보 가져오기
        if (userId == null && response['token'] != null) {
          print('토큰에서 userId를 추출할 수 없어 추가 요청으로 사용자 정보를 가져옵니다.');
          final userInfoResponse = await AuthService.getUserInfo(response['token'], email);
          print('사용자 정보 응답: $userInfoResponse');
          
          if (userInfoResponse['success'] && userInfoResponse['userId'] != null) {
            _userId = userInfoResponse['userId'];
            _userNickname = userInfoResponse['nickname'];
            
            print('사용자 정보 API에서 획득한 userId: $_userId, nickname: $_userNickname');
            
            if (_userId != null) {
              await prefs.setInt('userId', _userId!);
            } else {
              print('획득한 userId가 null입니다.');
            }
            
            if (_userNickname != null) {
              await prefs.setString('userNickname', _userNickname!);
            }
          } else {
            // 사용자 정보를 가져오지 못했어도 로그인은 성공한 상태이므로 계속 진행
            print('사용자 정보를 가져오는데 실패했지만 로그인은 성공 상태로 처리합니다.');
            _errorMessage = null; // 오류 메시지 제거
          }
        } else {
          _userId = userId;
          _userNickname = nickname;
          
          print('토큰에서 직접 획득한 userId: $_userId, nickname: $_userNickname');
          
          if (userId != null) {
            await prefs.setInt('userId', userId);
          } else {
            print('토큰에서 획득한 userId가 null입니다.');
          }
          
          if (nickname != null) {
            await prefs.setString('userNickname', nickname);
          }
        }
        
        await prefs.setString('userEmail', email);
        await prefs.setString('token', response['token']);
        
        // 자동 로그인 설정
        await prefs.setBool('autoLogin', autoLogin);
        
        _isLoggedIn = true;
        _userEmail = email;
        _token = response['token'];
        
        print('최종 로그인 상태: isLoggedIn=$_isLoggedIn, userId=$_userId, email=$_userEmail');
        
        // userId가 여전히 null인 경우 경고 출력 (개발 중 확인용)
        if (_userId == null) {
          print('⚠️ 경고: 로그인 완료되었지만 userId가 null입니다. 서버에서 사용자 식별이 필요한 기능은 작동하지 않을 수 있습니다.');
          // userId 없이도 로그인 상태를 허용하되, 사용자에게는 알리지 않음
        }
        
        _isLoading = false;
        notifyListeners();
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
  Future<bool> register(String email, String password, String name, String nickname, String mobile, bool fromSocial) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.register(email, password, name, nickname, mobile, fromSocial);
      
      if (response['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
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
} 