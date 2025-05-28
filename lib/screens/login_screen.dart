import 'package:flutter/material.dart';
import 'package:ourlog/services/worker_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // late 키워드를 사용하여 initState에서 초기화
  late final TextEditingController emailController;
  final TextEditingController passwordController = TextEditingController();
  bool autoLogin = false;

  @override
  void initState() {
    super.initState();
    // emailController는 didChangeDependencies에서 초기화됩니다.
    emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 인자에서 이메일을 가져와 컨트롤러 초기화합니다.
    // 이메일이 이미 채워져 있지 않은 경우에만 초기화합니다.
    final String? initialEmail = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialEmail != null && emailController.text.isEmpty) {
      emailController.text = initialEmail;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void  _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      emailController.text,
      passwordController.text,
      autoLogin: autoLogin,
    );
    
    if (success && mounted) {
      print('로그인 성공! 메인 화면으로 이동합니다.');

      final token = authProvider.token;
      if (token != null) {
        WorkerService.setAuthToken(token);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '환영합니다 ${authProvider.userNickname}님!\n이메일: ${authProvider.userEmail ?? '정보 없음'}\n사용자 ID: ${authProvider.userId ?? '정보 없음'}',
            style: const TextStyle(color: Color.fromRGBO(248, 193, 71, 100)),
          ),
          backgroundColor: Colors.black87,
        ),
      );
      
      // 로그인 성공 시 메인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider 로그인은 아직 구현되지 않았습니다.')),
    );
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고
                Image.asset(
                  'assets/images/OurLog.png',
                  height: 160,
                ),
                const SizedBox(height: 24),
                
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
                const Text(
                  '이메일',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2D2C2C)),
                  ),
                  child: TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '이메일 주소',
                      hintStyle: TextStyle(color: Color(0xFF8B8B8B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 비밀번호 입력
                const Text(
                  '비밀번호',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
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
                      hintText: '비밀번호',
                      hintStyle: TextStyle(color: Color(0xFF8B8B8B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 16),
                
                // 자동 로그인 체크박스
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: autoLogin,
                        onChanged: (value) {
                          setState(() {
                            autoLogin = value ?? false;
                          });
                        },
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
                    const Text(
                      '자동 로그인',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // 로그인 버튼
                authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BD7B5),
                          foregroundColor: const Color(0xFF23332C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '계속하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                
                // 소셜 로그인 버튼
                OutlinedButton.icon(
                  onPressed: () => _handleSocialLogin('Google'),
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
                  onPressed: () => _handleSocialLogin('Naver'),
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
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _handleSocialLogin('Kakao'),
                  icon: Image.asset('assets/images/Kakao.png', width: 24, height: 24),
                  label: const Text('카카오톡으로 계속하기'),
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
                
                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없나요?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'OurLog에 가입하기',
                        style: TextStyle(color: Color(0xFF9BCABF)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}