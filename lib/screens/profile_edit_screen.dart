// lib/screens/profile_edit_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  final int userId;

  const ProfileEditScreen({super.key, required this.userId});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();

  late TextEditingController _nickController;
  late TextEditingController _introController;
  String? _initialImageUrl;
  String? _initialNickname;
  String? _initialIntroduction;
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
      _initialNickname = prof.nickname;
      _initialIntroduction = prof.introduction;
      _initialImageUrl = prof.thumbnailImagePath;
    } catch (_) {
      // 에러 처리
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    debugPrint('★★★ _onSave 호출됨');
    debugPrint('    닉네임: ${_nickController.text}');
    debugPrint('    소개: ${_introController.text}');
    debugPrint(
      '    선택된 새 이미지 (_pickedImage): ${_pickedImage?.path}',
    ); // 파일 경로 출력
    debugPrint('    초기 이미지 URL (_initialImageUrl): $_initialImageUrl');

    setState(() => _loading = true);

    try {
      if (_pickedImage != null) {
        // 새 이미지를 선택한 경우
        String uploaded = await _service.uploadProfileImage(
          // uploaded 변수 타입 명시
          widget.userId,
          _pickedImage!,
        );
        final paths = uploaded.split(',');
        if (paths.length == 2) {
          final originPath = paths[0];
          final thumbnailPath = paths[1];

          // 이 requestBody 맵은 로그 출력용으로만 사용되고 실제 updateProfile 호출에는 사용되지 않습니다.
          final requestBody = {
            'originImagePath': originPath,
            'thumbnailImagePath': thumbnailPath,
            // 다른 필드들 (nickname, introduction 등)
          };
          debugPrint(
            '★★★ _onSave - uploadProfileImage 결과 (분리된 경로): $requestBody',
          ); // 로그 메시지 수정

          // 이미지 업로드 성공 후, 프로필 업데이트 API 호출 (새 이미지 경로 포함)
          // 닉네임과 소개는 변경되었는지 확인하여 전달합니다.
          final String? nicknameToUpdate =
              _nickController.text != _initialNickname
                  ? _nickController.text
                  : null;
          final String? introductionToUpdate =
              _introController.text != _initialIntroduction
                  ? _introController.text
                  : null;

          debugPrint('★★★ _onSave - 새 이미지 선택 시 updateProfile 요청 본문 직전');
          debugPrint('    닉네임 (변경됨): $nicknameToUpdate');
          debugPrint('    소개 (변경됨): $introductionToUpdate');
          // 분리된 경로를 각각 전달
          debugPrint('    새 원본 이미지 경로: $originPath');
          debugPrint('    새 썸네일 이미지 경로: $thumbnailPath');

          await _service.updateProfile(
            widget.userId,
            originImagePath: originPath,
            // 분리된 원본 이미지 경로 전달
            thumbnailImagePath: thumbnailPath,
            // 분리된 썸네일 이미지 경로 전달 (updateProfile 함수가 이 인자를 받는다고 가정)
            nickname: nicknameToUpdate,
            introduction: introductionToUpdate,
          );

          // 성공 메시지 및 화면 이동
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
          Navigator.of(context).pop(true);
          return; // 새 이미지를 선택한 경우 여기서 함수 종료
        } else {
          // uploadProfileImage가 예상과 다른 형식의 문자열을 반환한 경우
          debugPrint(
            '★★★ _onSave 오류: uploadProfileImage 반환값 형식 오류 - $uploaded',
          );
          throw Exception('이미지 업로드 경로 처리 오류');
        }
      } else {
        // 새로 이미지를 선택하지 않은 경우
        // 이미지 관련 경로는 전달하지 않아 백엔드가 기존 정보를 유지하도록 합니다.
        // 닉네임과 소개는 변경되었는지 확인하여 전달합니다.
        final String? nicknameToUpdate =
            _nickController.text != _initialNickname
                ? _nickController.text
                : null;
        final String? introductionToUpdate =
            _introController.text != _initialIntroduction
                ? _introController.text
                : null;

        debugPrint('★★★ _onSave - 이미지 미선택 시 updateProfile 요청 본문 직전');
        debugPrint('    닉네임 (변경됨): $nicknameToUpdate');
        debugPrint('    소개 (변경됨): $introductionToUpdate');

        await _service.updateProfile(
          widget.userId,
          nickname: nicknameToUpdate,
          introduction: introductionToUpdate,
          // originImagePath와 thumbnailImagePath는 전달하지 않음
        );

        // 성공 메시지 및 화면 이동
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
        Navigator.of(context).pop(true);
        // 함수는 여기서 자연스럽게 종료됩니다.
      }
    } catch (e) {
      debugPrint('프로필 저장 실패 오류: ${e.runtimeType} - $e'); // 오류 타입 및 메시지 로그 추가
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
    } finally {
      // 로딩 상태 해제는 성공/실패와 관계없이 실행
      setState(() => _loading = false);
    }
    // 혹시 try-catch 블록 밖에서 발생하는 오류를 잡기 위한 로그
    // 이 로그가 출력된다면 오류의 원인이 try-catch 블록 내부에 없음을 의미합니다.
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('★★★ ProfileEditScreen Global Error: ${details.exception}');
      debugPrint('★★★ Stack Trace: ${details.stack}');
    };
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
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(backgroundColor: Colors.black, title: const Text('프로필수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                        color: const Color(0xFF333333),
                        width: 2,
                      ),
                      color: const Color(0xFF232323),
                    ),
                    child: ClipOval(
                      child: Builder(
                        builder: (BuildContext context) {
                          if (_pickedImage != null) {
                            // 새로 선택한 이미지가 있는 경우
                            return Image.file(_pickedImage!, fit: BoxFit.cover);
                          } else if (_initialImageUrl != null &&
                              _initialImageUrl!.isNotEmpty) {
                            // 기존 프로필 이미지가 있는 경우 (URL이 유효한지 확인)
                            // NetworkImage가 String을 기대하므로, null이 아님을 단언해도 안전합니다.
                            try {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final token = authProvider.token;

                              return Image.network(
                                'http://10.100.204.124:8080' +
                                    _initialImageUrl!,
                                fit: BoxFit.cover,
                                headers:
                                    token != null
                                        ? {'Authorization': 'Bearer $token'}
                                        : null,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                    '프로필 이미지 로딩 오류: $_initialImageUrl - $error',
                                  );
                                  return const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Color(0xFF999999),
                                  ); // 오류 시 기본 아이콘
                                },
                              );
                            } catch (e) {
                              debugPrint(
                                'NetworkImage 생성 중 오류: $_initialImageUrl - $e',
                              );
                              return const Icon(
                                Icons.person,
                                size: 80,
                                color: Color(0xFF999999),
                              ); // 오류 시 기본 아이콘
                            }
                          } else {
                            // 이미지가 없는 경우 (기본 아이콘 표시)
                            return const Icon(
                              Icons.person,
                              size: 80,
                              color: Color(0xFF999999),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF333333),
                    onPressed: _pickImage,
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 기본 정보 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '기본 정보',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 닉네임
                    TextFormField(
                      controller: _nickController,
                      style: const TextStyle(color: Color(0xFFCCCCCC)),
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        labelStyle: const TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: const Color(0xFF232323),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFF8C147),
                          ),
                        ),
                      ),
                      validator:
                          (v) => (v == null || v.isEmpty) ? '닉네임을 입력하세요' : null,
                    ),
                    const SizedBox(height: 20),

                    // 소개
                    TextFormField(
                      controller: _introController,
                      maxLines: 4,
                      style: const TextStyle(color: Color(0xFFCCCCCC)),
                      decoration: InputDecoration(
                        labelText: '소개',
                        labelStyle: const TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: const Color(0xFF232323),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF333333),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFF8C147),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 액션 버튼
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: const Color(0xFFCCCCCC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8C147),
                      foregroundColor: const Color(0xFF111111),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _onSave,
                    child: const Text('변경사항 저장'),
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
