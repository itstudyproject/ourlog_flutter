// // lib/screens/profile_edit_screen.dart
//
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/user_profile.dart';
// import '../services/profile_service.dart';
// import '../constants/theme.dart'; // 필요하면 여러분 테마 클래스
//
// class ProfileEditScreen extends StatefulWidget {
//   final int userId;
//
//   const ProfileEditScreen({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   _ProfileEditScreenState createState() => _ProfileEditScreenState();
// }
//
// class _ProfileEditScreenState extends State<ProfileEditScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _service = ProfileService();
//
//   // 컨트롤러
//   late TextEditingController _nickController;
//   late TextEditingController _introController;
//   File? _pickedImage;
//   bool _loading = true;
//
//   // 초기 데이터 로드
//   @override
//   void initState() {
//     super.initState();
//     _nickController = TextEditingController();
//     _introController = TextEditingController();
//     _loadProfile();
//   }
//
//   Future<void> _loadProfile() async {
//     try {
//       final profile = await _service.fetchProfile(widget.userId);
//       _nickController.text = profile.nickname;
//       _introController.text =
//           profile
//               .thumbnailImagePath /* 설명에는 introduction 이지만, DTO 필드 이름에 맞추세요 */;
//     } catch (e) {
//       // TODO: 에러 처리
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   // 이미지 픽
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (file != null) {
//       setState(() {
//         _pickedImage = File(file.path);
//       });
//     }
//   }
//
//   Future<void> _onSave() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _loading = true);
//
//     try {
//       // Partial<UserProfileDTO> 에 맞춰서 DTO 생성
//       final updated = UserProfile(
//         nickname: _nickController.text,
//         thumbnailImagePath: _pickedImage?.path ?? '',
//         followCnt: 0,
//         followingCnt: 0,
//         introduction: '',
//       );
//       await _service.updateProfile(widget.userId, updated);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
//       Navigator.of(context).pop();
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   @override
//   void dispose() {
//     _nickController.dispose();
//     _introController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1A1A1A),
//       appBar: AppBar(
//         title: const Text('프로필수정'),
//         backgroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body:
//           _loading
//               ? const Center(child: CircularProgressIndicator())
//               : SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       // 프로필 사진
//                       Stack(
//                         alignment: Alignment.bottomRight,
//                         children: [
//                           Container(
//                             width: 150,
//                             height: 150,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: const Color(0xFF333333),
//                                 width: 2,
//                               ),
//                               color: const Color(0xFF232323),
//                             ),
//                             child: ClipOval(
//                               child:
//                                   _pickedImage != null
//                                       ? Image.file(
//                                         _pickedImage!,
//                                         fit: BoxFit.cover,
//                                       )
//                                       : Image.network(
//                                         _service
//                                             .fetchProfile(
//                                               widget.userId,
//                                             ) // 이미 불러온 URL이어야 합니다
//                                             .then((p) => p.thumbnailImagePath)
//                                             .toString(),
//                                         fit: BoxFit.cover,
//                                       ),
//                             ),
//                           ),
//                           FloatingActionButton(
//                             mini: true,
//                             backgroundColor: const Color(0xFF333333),
//                             onPressed: _pickImage,
//                             child: const Icon(
//                               Icons.camera_alt,
//                               color: Color(0xFFCCCCCC),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 30),
//
//                       // 기본 정보 섹션
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF232323),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               '기본 정보',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//
//                             // 닉네임
//                             TextFormField(
//                               controller: _nickController,
//                               style: const TextStyle(color: Color(0xFFCCCCCC)),
//                               decoration: InputDecoration(
//                                 labelText: '닉네임',
//                                 labelStyle: const TextStyle(
//                                   color: Color(0xFF999999),
//                                 ),
//                                 filled: true,
//                                 fillColor: const Color(0xFF232323),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF333333),
//                                   ),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFFF8C147),
//                                   ),
//                                 ),
//                               ),
//                               validator:
//                                   (v) =>
//                                       (v == null || v.isEmpty)
//                                           ? '닉네임을 입력하세요'
//                                           : null,
//                             ),
//                             const SizedBox(height: 20),
//
//                             // 소개
//                             TextFormField(
//                               controller: _introController,
//                               maxLines: 4,
//                               style: const TextStyle(color: Color(0xFFCCCCCC)),
//                               decoration: InputDecoration(
//                                 labelText: '소개',
//                                 labelStyle: const TextStyle(
//                                   color: Color(0xFF999999),
//                                 ),
//                                 filled: true,
//                                 fillColor: const Color(0xFF232323),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF333333),
//                                   ),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFFF8C147),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       // 버튼
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           // 취소
//                           OutlinedButton(
//                             style: OutlinedButton.styleFrom(
//                               backgroundColor: const Color(0xFF333333),
//                               foregroundColor: const Color(0xFFCCCCCC),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 10,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             onPressed: () => Navigator.of(context).pop(),
//                             child: const Text('취소'),
//                           ),
//                           const SizedBox(width: 12),
//                           // 저장
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFFF8C147),
//                               foregroundColor: const Color(0xFF111111),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 10,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             onPressed: _onSave,
//                             child: const Text('변경사항 저장'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//     );
//   }
// }
//
//
