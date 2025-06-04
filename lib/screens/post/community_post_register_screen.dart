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
  // 텍스트 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  /// 1) 서버에 이미 저장되어 있던 기존 이미지들 (수정 모드일 때만)
  List<Picture> _existingPictures = [];

  /// 2) 로컬에서 새로 골라둔 File 들 (아직 서버에 업로드되지 않음)
  List<File> _newPickedFiles = [];

  /// 3) 새로 업로드된 후 서버가 응답한 Picture 객체들
  List<Picture> _uploadedNewPictures = [];

  /// 4) 썸네일로 선택된 이미지의 ID (서버에 있던 이미지는 picId, 업로드 직후에도 picId;
  ///    로컬만 선택된 상태라면 file.hashCode를 임시 ID로 사용)
  int? _selectedThumbnailId;

  @override
  void initState() {
    super.initState();

    // 수정 모드라면, 기존 Post 데이터를 넣어둡니다.
    if (widget.postToEdit != null) {
      final post = widget.postToEdit!;

      _titleController.text = post.title ?? '';
      _contentController.text = post.content ?? '';
      _tagController.text = post.tag ?? '';

      if (post.pictureDTOList != null) {
        // Post.pictureDTOList 는 List<Picture> 타입이라고 가정
        _existingPictures = List<Picture>.from(post.pictureDTOList!);
      }

      // 기존 썸네일 ID 기억
      if (post.thumbnailImagePath != null && post.pictureDTOList != null) {
        final idx = post.pictureDTOList!
            .indexWhere((p) => p.thumbnailImagePath == post.thumbnailImagePath);
        if (idx >= 0) {
          _selectedThumbnailId = post.pictureDTOList![idx].picId;
        }
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

  /// 이미지 선택 (갤러리에서 다중 선택) → 로컬 파일 리스트에 추가 (중복 방지)
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    setState(() {
      for (var x in pickedFiles) {
        final f = File(x.path);

        // 1) 이미 로컬에서 고른 파일인지 검사
        final isLocalDup = _newPickedFiles.any((e) => e.path == f.path);

        // 2) 기존 서버 이미지 중 같은 originImagePath 가 있는지 검사
        final isServerDup = _existingPictures.any(
                (p) => p.originImagePath != null && p.originImagePath == x.path);

        if (!isLocalDup && !isServerDup) {
          _newPickedFiles.add(f);
        }
      }
    });
  }

  /// 로컬에서 고른 파일들을 순차 업로드 → 응답 Picture 객체를 _uploadedNewPictures 에 저장
  Future<void> _uploadNewPickedFiles() async {
    if (_newPickedFiles.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      for (final file in _newPickedFiles) {
        final result = await PictureService.uploadImage(file);
        final pic = Picture.fromJson(result as Map<String, dynamic>);
        _uploadedNewPictures.add(pic);

        // 만약 이 파일의 hashCode를 기존 썸네일 ID로 잡아뒀다면
        // 업로드된 pic.picId 로 _selectedThumbnailId 를 교체
        if (file.hashCode == _selectedThumbnailId) {
          _selectedThumbnailId = pic.picId;
        }
      }
      _newPickedFiles.clear();
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 업로드 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 썸네일로 선택 (nullable int 를 받도록 변경)
  void _selectThumbnail(int? id) {
    if (id == null) return;
    setState(() {
      _selectedThumbnailId = id;
    });
  }

  /// 최종 등록 혹은 수정
  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tag = _tagController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() {
        _errorMessage = '제목과 내용을 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1) 새로 골라둔 로컬 이미지가 있다면 서버에 업로드
      await _uploadNewPickedFiles();

      // 2) 기존 서버 이미지 + 새로 업로드된 이미지 합치기
      final combinedPictures = <Picture>[];
      combinedPictures.addAll(_existingPictures);
      combinedPictures.addAll(_uploadedNewPictures);

      // 3) 선택된 썸네일 ID 로부터 thumbnailImagePath 를 찾아 저장
      String? thumbnailPath;
      if (_selectedThumbnailId != null) {
        final selPic = combinedPictures.firstWhere(
              (p) => p.picId == _selectedThumbnailId,
          orElse: () => combinedPictures.first,
        );
        thumbnailPath = selPic.thumbnailImagePath;
      }

      // 4) Post 객체 생성 (수정 모드라면 postId 등 그대로, 신규 모드면 boardNo 계산)
      final newPost = Post(
        postId: widget.postToEdit?.postId,
        userId: widget.postToEdit?.userId,
        userDTO: widget.postToEdit?.userDTO,
        title: title,
        content: content,
        nickname: widget.postToEdit?.nickname,
        fileName: widget.postToEdit?.fileName,
        boardNo: widget.postToEdit?.boardNo ??
            _boardTypeToNo(widget.boardType),
        views: widget.postToEdit?.views,
        tag: tag.isEmpty ? null : tag,
        thumbnailImagePath: thumbnailPath,
        resizedImagePath: widget.postToEdit?.resizedImagePath,
        originImagePath: widget.postToEdit?.originImagePath,
        followers: widget.postToEdit?.followers,
        downloads: widget.postToEdit?.downloads,
        favoriteCnt: widget.postToEdit?.favoriteCnt,
        tradeDTO: widget.postToEdit?.tradeDTO,
        pictureDTOList: combinedPictures,
        profileImage: widget.postToEdit?.profileImage,
        replyCnt: widget.postToEdit?.replyCnt,
        regDate: widget.postToEdit!.regDate,
        modDate: widget.postToEdit!.modDate,
        liked: widget.postToEdit?.liked ?? false,
      );

      if (widget.postToEdit == null) {
        // 신규 등록
        await PostService.createPost(newPost);
      } else {
        // 수정 모드
        await PostService.updatePost(newPost);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage =
        '게시글 ${widget.postToEdit == null ? '등록' : '수정'} 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int? _boardTypeToNo(String? boardType) {
    switch (boardType) {
      case 'news':
        return 1;
      case 'free':
        return 2;
      case 'promotion':
        return 3;
      case 'request':
        return 4;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = (widget.postToEdit != null);

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
              ? const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          )
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 제목 입력 ──────────────────────────────────────
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 태그 입력 (선택사항) ────────────────────────────
                TextField(
                  controller: _tagController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '태그를 입력하세요 (선택사항)',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 이미지 섹션 ────────────────────────────────────
                const Text(
                  '이미지 추가',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 1) 기존에 서버에 저장된 이미지들 (수정 모드에서만)
                if (_existingPictures.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '기존 이미지들 (수정 시)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _existingPictures.map((pic) {
                          final imageUrl = pic.thumbnailImagePath != null
                              ? "http://10.100.204.189:8080/ourlog/picture/display/${pic.thumbnailImagePath}"
                              : "http://10.100.204.189:8080/ourlog/picture/display/default-image.jpg";
                          final bool isSelected =
                          (pic.picId == _selectedThumbnailId);

                          return GestureDetector(
                            onTap: () => _selectThumbnail(pic.picId),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border.all(
                                        color: Colors.blueAccent,
                                        width: 3)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Icon(Icons.check_circle,
                                        color: Colors.blueAccent),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // 2) 로컬에서 선택만 해둔 파일들(아직 서버 업로드 전)
                if (_newPickedFiles.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새로 선택된 이미지(서버 업로드 전)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _newPickedFiles.map((file) {
                          final fakeId = file.hashCode;
                          final bool isSelected =
                          (fakeId == _selectedThumbnailId);

                          return GestureDetector(
                            onTap: () => _selectThumbnail(fakeId),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border.all(
                                        color: Colors.blueAccent,
                                        width: 3)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Icon(Icons.check_circle,
                                        color: Colors.blueAccent),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // 3) 아직 서버에 업로드되지 않은 새 이미지가 없을 때만 “이미지 선택” 버튼
                if (_newPickedFiles.isEmpty)
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('이미지 선택'),
                  ),

                // 4) 새 이미지가 선택되어 있으면 “서버 업로드” 버튼
                if (_newPickedFiles.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _uploadNewPickedFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('서버에 업로드'),
                  ),

                const SizedBox(height: 24),

                // ─── 내용 입력 ─────────────────────────────────────────
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 에러 메시지 ─────────────────────────────────────────
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),

                // ─── 등록/수정 버튼 ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
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
