// lib/screens/post/community_post_register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/picture.dart';
import '../../models/post.dart';
import '../../services/picture_service.dart';
import '../../services/post_service.dart';

/// postToEdit 가 null 이면 “신규 등록 모드”, null 이 아니면 “수정 모드”로 동작합니다.
class CommunityPostRegisterScreen extends StatefulWidget {
  final Post? postToEdit;
  final String? boardType;

  const CommunityPostRegisterScreen({
    Key? key,
    this.postToEdit,
    this.boardType,
  }) : super(key: key);

  @override
  State<CommunityPostRegisterScreen> createState() =>
      _CommunityPostRegisterScreenState();
}

class _CommunityPostRegisterScreenState
    extends State<CommunityPostRegisterScreen> {
  // ─── 카테고리 선택 상태 ─────────────────────────────────
  String? _selectedBoardType;
  final _categories = [
    {'value': 'news', 'label': '소식 게시판'},
    {'value': 'free', 'label': '자유 게시판'},
    {'value': 'promotion', 'label': '홍보 게시판'},
    {'value': 'request', 'label': '요청 게시판'},
  ];

  // 텍스트 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  /// 1) 서버에 이미 저장되어 있던 기존 이미지들
  List<Picture> _existingPictures = [];

  /// 2) 로컬에서 새로 골라둔 File 들
  List<File> _newPickedFiles = [];

  /// 3) 새로 업로드된 후 서버가 응답한 Picture 객체들
  List<Picture> _uploadedNewPictures = [];

  /// 4) 썸네일로 선택된 이미지의 ID
  int? _selectedThumbnailId;

  @override
  void initState() {
    super.initState();

    // 기존 boardType 초기화
    _selectedBoardType = widget.boardType ?? _categories.first['value'];

    if (widget.postToEdit != null) {
      final post = widget.postToEdit!;
      _titleController.text = post.title ?? '';
      _contentController.text = post.content ?? '';
      _tagController.text = post.tag ?? '';

      if (post.pictureDTOList != null) {
        _existingPictures = List<Picture>.from(post.pictureDTOList!);
      }

      if (post.thumbnailImagePath != null && post.pictureDTOList != null) {
        final idx = post.pictureDTOList!
            .indexWhere((p) => p.thumbnailImagePath == post.thumbnailImagePath);
        if (idx >= 0) _selectedThumbnailId = post.pictureDTOList![idx].picId;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    setState(() {
      for (var x in pickedFiles) {
        final f = File(x.path);
        final isLocalDup = _newPickedFiles.any((e) => e.path == f.path);
        final isServerDup = _existingPictures.any(
              (p) => p.originImagePath != null && p.originImagePath == x.path,
        );
        if (!isLocalDup && !isServerDup) {
          _newPickedFiles.add(f);
        }
      }
    });
  }

  Future<void> _uploadNewPickedFiles() async {
    if (_newPickedFiles.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      for (final file in _newPickedFiles) {
        final result = await PictureService.uploadImage(file);
        final pic = Picture.fromJson(result as Map<String, dynamic>);
        _uploadedNewPictures.add(pic);
        if (file.hashCode == _selectedThumbnailId) {
          _selectedThumbnailId = pic.picId;
        }
      }
      _newPickedFiles.clear();
    } catch (e) {
      setState(() { _errorMessage = '이미지 업로드 실패: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _selectThumbnail(int? id) {
    if (id == null) return;
    setState(() { _selectedThumbnailId = id; });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() { _errorMessage = '제목과 내용을 입력해주세요.'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      await _uploadNewPickedFiles();
      final combinedPictures = [..._existingPictures, ..._uploadedNewPictures];

      String? thumbnailPath;
      if (_selectedThumbnailId != null) {
        final sel = combinedPictures.firstWhere(
              (p) => p.picId == _selectedThumbnailId,
          orElse: () => combinedPictures.first,
        );
        thumbnailPath = sel.thumbnailImagePath;
      }

      final newPost = Post(
        postId: widget.postToEdit?.postId,
        userId: widget.postToEdit?.userId,
        userDTO: widget.postToEdit?.userDTO,
        title: title,
        content: content,
        tag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
        boardNo: _boardTypeToNo(_selectedBoardType),
        thumbnailImagePath: thumbnailPath,
        pictureDTOList: combinedPictures,
        // ... 다른 필드 유지
      );

      if (widget.postToEdit == null) {
        await PostService.createPost(newPost);
      } else {
        await PostService.updatePost(newPost);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _errorMessage = '오류 발생: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  int? _boardTypeToNo(String? boardType) {
    switch (boardType) {
      case 'news': return 1;
      case 'free': return 2;
      case 'promotion': return 3;
      case 'request': return 4;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.postToEdit != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isEditMode ? '게시글 수정' : '새 게시글 작성'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 선택
                const Text('카테고리', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedBoardType,
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c['value'],
                    child: Text(c['label']!, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: Colors.black87,
                  onChanged: (v) => setState(() => _selectedBoardType = v),
                ),
                const SizedBox(height: 16),


                // 제목 입력
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력하세요', hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                // 태그 입력
                TextField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '태그를 입력하세요 (선택사항)', hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // 이미지 섹션
                const Text('이미지 추가', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (_existingPictures.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('기존 이미지들 (수정 시)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _existingPictures.map((pic) {
                          final imageUrl = pic.thumbnailImagePath != null
                              ? "http://192.168.219.102:8080/ourlog/picture/display/\${pic.thumbnailImagePath}"
                              : "http://192.168.219.102:8080/ourlog/picture/display/default-image.jpg";
                          final isSelected = pic.picId == _selectedThumbnailId;
                          return GestureDetector(
                            onTap: () => _selectThumbnail(pic.picId),
                            child: Stack(alignment: Alignment.topRight, children: [
                              Container(width: 100,height:100,decoration: BoxDecoration(
                                border: isSelected ? Border.all(color: Colors.blueAccent, width: 3) : null,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                              )),
                              if (isSelected) const Positioned(top:4,right:4,child: Icon(Icons.check_circle,color:Colors.blueAccent)),
                            ]),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                if (_newPickedFiles.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('새로 선택된 이미지(서버 업로드 전)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _newPickedFiles.map((file) {
                          final fakeId = file.hashCode;
                          final isSelected = fakeId == _selectedThumbnailId;
                          return GestureDetector(
                            onTap: () => _selectThumbnail(fakeId),
                            child: Stack(alignment: Alignment.topRight, children: [
                              Container(width:100,height:100,decoration: BoxDecoration(
                                border: isSelected ? Border.all(color:Colors.blueAccent,width:3):null,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                              )),
                              if (isSelected) const Positioned(top:4,right:4,child: Icon(Icons.check_circle,color:Colors.blueAccent)),
                            ]),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height:16),
                    ],
                  ),

                if (_newPickedFiles.isEmpty)
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10,foregroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.add_photo_alternate), label: const Text('이미지 선택'),
                  ),

                if (_newPickedFiles.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _uploadNewPickedFiles,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10,foregroundColor: Colors.white,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.cloud_upload), label: const Text('서버에 업로드'),
                  ),

                const SizedBox(height:24),

                // 내용 입력
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요', hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height:24),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom:12),
                    child: Text(_errorMessage, style: const TextStyle(color:Colors.redAccent)),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: Text(isEditMode ? '수정 완료' : '등록'),
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
