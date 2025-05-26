import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DeleteUserScreen extends StatefulWidget {
  const DeleteUserScreen({super.key});

  @override
  State<DeleteUserScreen> createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  final TextEditingController passwordController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 사용자 정보 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserInfo();
    });
  }

  // 사용자 정보 확인
  void _checkUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 로그인 화면으로 이동합니다.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    // userId가 null인 경우 경고 표시
    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('사용자 정보를 불러오는 중입니다. 잠시만 기다려주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteUser() async {
    if (_isDeleting) return; // 중복 요청 방지
    
    setState(() {
      _isDeleting = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
      setState(() {
        _isDeleting = false;
      });
      return;
    }
    
    // 사용자에게 최종 확인
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      setState(() {
        _isDeleting = false;
      });
      return;
    }
    
    // 버튼 상태 업데이트
    try {
      final success = await authProvider.deleteAccount();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
        );
        // 로그인 화면으로 이동
        Navigator.pushReplacementNamed(context, '/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? '회원탈퇴에 실패했습니다.'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isProcessing = authProvider.isLoading || _isDeleting;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('회원탈퇴', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 키보드가 올라올 때 화면이 스크롤되도록 SingleChildScrollView 추가
      body: SingleChildScrollView(
        // 키보드가 표시될 때 화면을 조정하도록 설정
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '정말 탈퇴하시겠습니까?',
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              
              // 계정 정보 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D2C2C)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '계정 정보',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이메일: ${authProvider.userEmail ?? '알 수 없음'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (authProvider.userNickname != null)
                      Text(
                        '닉네임: ${authProvider.userNickname}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    Text(
                      '사용자 ID: ${authProvider.userId ?? '정보 없음'}',
                      style: TextStyle(
                        color: authProvider.userId == null ? Colors.red[300] : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 에러 메시지
              if (authProvider.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              
              // 비밀번호 확인 필드
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D2C2C)),
                ),
                child: TextField(
                  controller: passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '비밀번호 확인',
                    hintStyle: TextStyle(color: Color(0xFF8B8B8B)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 40),
              
              // 회원탈퇴 버튼
              isProcessing
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : ElevatedButton(
                      onPressed: authProvider.userId == null ? null : _deleteUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: const Text(
                        '회원탈퇴',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
              // 사용자 ID가 없는 경우 안내 메시지
              if (authProvider.userId == null && !isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    '사용자 정보가 확인되지 않습니다. 다시 로그인 후 시도해주세요.',
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              // 키보드가 올라올 때 추가 여백 확보
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 120 : 0),
            ],
          ),
        ),
      ),
      // 키보드가 오버레이 되도록 설정
      resizeToAvoidBottomInset: false,
    );
  }
  
  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}