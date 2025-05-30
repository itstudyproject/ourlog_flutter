import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  bool termsAgreed = false;
  bool privacyAgreed = false;
  bool isSocialRegister = false;

  void _register() async {
    // 비밀번호 확인
    if (passwordController.text != passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    // 필수 동의사항 확인
    if (!termsAgreed || !privacyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해주세요.')),
      );
      return;
    }

    // 빈 필드 확인
    if (emailController.text.isEmpty || 
        passwordController.text.isEmpty || 
        passwordConfirmController.text.isEmpty || 
        nameController.text.isEmpty || 
        nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 정보를 입력해주세요.')),
      );
      return;
    }


    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      emailController.text,
      passwordController.text,
      passwordConfirmController.text,
      nameController.text,
      nicknameController.text,
      mobileController.text,
      isSocialRegister
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공!')),
      );
      Navigator.pop(context); // 회원가입 후 이전 화면(로그인)으로 이동
    } else if (mounted) {
      // 회원가입 실패 시 errorMessage는 이미 authProvider에 설정되어 있어 화면에 표시됨
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? '회원가입에 실패했습니다.')),
      );
    }
  }

  // 소셜 로그인 처리 메서드
  void _handleSocialLogin(String provider) async {
    setState(() {
      isSocialRegister = true; // 소셜 로그인으로 설정
    });
    
    // 여기서 실제 소셜 로그인 구현
    // 예: 구글 로그인 후 제공되는 이메일 및 정보로 필드 채우기
    
    // 현재는 소셜 로그인이 구현되지 않았으므로 알림만 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider 로그인으로 진행합니다. 추가 정보를 입력하세요.')),
    );
    
    // 소셜 계정으로부터 받은 이메일 등 정보로 필드 초기화 (예시)
    // emailController.text = socialAccount.email;
    // nameController.text = socialAccount.name;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로고
              Image.asset(
                'assets/images/OurLog.png',
                height: 140,
              ),
              const SizedBox(height: 16),
              
              // 소셜 로그인 상태 표시
              if (isSocialRegister)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Text(
                    '소셜 계정으로 가입을 진행합니다. 추가 정보를 입력해주세요.',
                    style: TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
              
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
              const SizedBox(height: 24),
              
              // 이메일 입력
              _buildInputField(
                label: '이메일',
                hintText: '이메일 주소',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isSocialRegister, // 소셜 로그인일 경우 비활성화
              ),
              const SizedBox(height: 16),
              
              // 이름 입력
              _buildInputField(
                label: '이름',
                hintText: '이름',
                controller: nameController,
              ),
              const SizedBox(height: 16),
              
              // 닉네임 입력
              _buildInputField(
                label: '닉네임',
                hintText: '닉네임',
                controller: nicknameController,
              ),
              const SizedBox(height: 16),
              
              // 비밀번호 입력 (소셜 로그인이 아닐 때만 표시)
              if (!isSocialRegister)
                _buildInputField(
                  label: '비밀번호',
                  hintText: '비밀번호',
                  controller: passwordController,
                  isPassword: true,
                ),
              if (!isSocialRegister)
                const SizedBox(height: 16),
              
              // 비밀번호 확인 입력 (소셜 로그인이 아닐 때만 표시)
              if (!isSocialRegister)
                _buildInputField(
                  label: '비밀번호 확인',
                  hintText: '비밀번호 확인',
                  controller: passwordConfirmController
                  ,
                  isPassword: true,
                ),
              if (!isSocialRegister)
                const SizedBox(height: 16),
              
              // 전화번호 입력
              _buildInputField(
                label: '전화번호',
                hintText: '전화번호',
                controller: mobileController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              
              // 약관 동의
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckbox(
                      value: termsAgreed,
                      onChanged: (value) {
                        setState(() {
                          termsAgreed = value ?? false;
                        });
                      },
                      label: '이용약관에 동의합니다. (필수)',
                      onTap: () {
                        // 이용약관 페이지로 이동
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCheckbox(
                      value: privacyAgreed,
                      onChanged: (value) {
                        setState(() {
                          privacyAgreed = value ?? false;
                        });
                      },
                      label: '개인정보 처리방침에 동의합니다. (필수)',
                      onTap: () {
                        // 개인정보 처리방침 페이지로 이동
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 가입하기 버튼
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BD7B5),
                        foregroundColor: const Color(0xFF23332C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '가입하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              
              // 소셜 로그인 버튼
              OutlinedButton.icon(
                onPressed: () {
                  _handleSocialLogin('Google');
                },
                icon: Image.asset('assets/images/Google.png', width: 24, height: 24),
                label: const Text('Google로 계속하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _handleSocialLogin('Naver');
                },
                icon: Image.asset('assets/images/Naver.png', width: 24, height: 24),
                label: const Text('Naver로 계속하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF121212),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2D2C2C)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            obscureText: isPassword,
            keyboardType: keyboardType,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            fillColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF9BCABF);
                }
                return Colors.transparent;
              },
            ),
            side: const BorderSide(color: Color(0xFF9BCABF)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
