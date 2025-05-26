import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final int userId;
  const ProfileEditScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();

  late TextEditingController _nickController;
  late TextEditingController _introController;
  String? _initialImageUrl;
  File? _pickedImage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nickController = TextEditingController();
    _introController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prof = await _service.fetchProfile(widget.userId);
      _nickController.text = prof.nickname;
      _introController.text = prof.introduction;
      _initialImageUrl = prof.thumbnailImagePath;
    } catch (_) {
      // 에러 처리
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? uploaded;
      if (_pickedImage != null) {
        uploaded = await _service.uploadProfileImage(
          widget.userId,
          _pickedImage!,
        );
      }

      await _service.updateProfile(
        widget.userId,
        nickname: _nickController.text,
        introduction: _introController.text,
        originImagePath: uploaded,
        thumbnailImagePath: uploaded,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('프로필이 저장되었습니다.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장에 실패했습니다.')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nickController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('프로필수정'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 프로필 사진
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF333333),
                        width: 2,
                      ),
                      color: Color(0xFF232323),
                    ),
                    child: ClipOval(
                      child: _pickedImage != null
                          ? Image.file(_pickedImage!, fit: BoxFit.cover)
                          : (_initialImageUrl == null ||
                          _initialImageUrl == '/images/mypage.png'
                          ? Image.asset(
                        'assets/images/mypage.png',
                        fit: BoxFit.cover,
                      )
                          : Image.network(
                        'http://10.100.204.189:8080/ourlog$_initialImageUrl',
                        fit: BoxFit.cover,
                      )),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Color(0xFF333333),
                    onPressed: _pickImage,
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // 기본 정보 섹션
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기본 정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24),

                    // 닉네임
                    TextFormField(
                      controller: _nickController,
                      style: TextStyle(color: Color(0xFFCCCCCC)),
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: Color(0xFF232323),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF333333)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFF8C147)),
                        ),
                      ),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? '닉네임을 입력하세요' : null,
                    ),
                    SizedBox(height: 20),

                    // 소개
                    TextFormField(
                      controller: _introController,
                      maxLines: 4,
                      style: TextStyle(color: Color(0xFFCCCCCC)),
                      decoration: InputDecoration(
                        labelText: '소개',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: Color(0xFF232323),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF333333)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFF8C147)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 액션 버튼
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xFF333333),
                      foregroundColor: Color(0xFFCCCCCC),
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('취소'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF8C147),
                      foregroundColor: Color(0xFF111111),
                      padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _onSave,
                    child: Text('변경사항 저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
