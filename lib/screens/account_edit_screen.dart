// lib/screens/account_edit_screen.dart

import 'package:flutter/material.dart';
import '../services/user_service.dart'; // updateUserInfo 등 API 호출 정의
import '../models/user.dart';          // UserDTO 대응 모델

class AccountEditScreen extends StatefulWidget {
  final int userId;
  const AccountEditScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AccountEditScreenState createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _mobileCtrl    = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await UserService.fetchUser(widget.userId);
      _mobileCtrl.text = user.mobile ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await UserService.updateUserInfo(
        widget.userId,
        password: _newPwCtrl.text,
        mobile: _mobileCtrl.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원정보가 변경되었습니다.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경에 실패했습니다: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF999999)),
      filled: true,
      fillColor: const Color(0xFF232323),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF333333)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF8C147)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('회원정보수정'),
        leading: BackButton(color: Colors.amber),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 현재 비밀번호
              TextFormField(
                controller: _currentPwCtrl,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFCCCCCC)),
                decoration: _buildDecoration('현재 비밀번호'),
                validator: (v) =>
                (v == null || v.isEmpty) ? '현재 비밀번호를 입력하세요' : null,
              ),
              const SizedBox(height: 20),

              // 새 비밀번호
              TextFormField(
                controller: _newPwCtrl,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFCCCCCC)),
                decoration: _buildDecoration('새 비밀번호'),
                validator: (v) =>
                (v == null || v.isEmpty) ? '새 비밀번호를 입력하세요' : null,
              ),
              const SizedBox(height: 20),

              // 새 비밀번호 확인
              TextFormField(
                controller: _confirmPwCtrl,
                obscureText: true,
                style: const TextStyle(color: Color(0xFFCCCCCC)),
                decoration: _buildDecoration('새 비밀번호 확인'),
                validator: (v) =>
                (v == null || v.isEmpty) ? '비밀번호 확인을 입력하세요' : null,
              ),
              const SizedBox(height: 20),

              // 연락처
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFFCCCCCC)),
                decoration: _buildDecoration('연락처'),
              ),
              const SizedBox(height: 30),

              // 변경하기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _onSubmit,
                  child: const Text('변경하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
