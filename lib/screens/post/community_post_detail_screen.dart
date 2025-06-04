// lib/screens/post/community_post_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/post.dart';
import '../../models/picture.dart';
import '../../services/post_service.dart';
import '../../services/picture_service.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final int postId;
  const CommunityPostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isEditing = false;
  bool _isPickingImage = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  /// 기존 서버에 있던 이미지 목록
  List<Picture> _existingPictures = [];

  /// 로컬에서 새로 고른 이미지(File)
  List<File> _newAttachedImages = [];

  /// 새로 서버에 업로드된 Picture 객체 리스트
  List<Picture> _uploadedNewPictures = [];

  /// 선택된 썸네일 ID (nullable)
  int? _selectedThumbnailId;

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 서버에서 Post 상세 정보 가져오기
  Future<void> _fetchPostDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final fetched = await PostService.getPostById(widget.postId);
      setState(() {
        _post = fetched;
        _isLoading = false;

        // 기존 서버 이미지 목록 복사
        _existingPictures = List<Picture>.from(fetched.pictureDTOList ?? []);

        // 기존 썸네일 설정이 되어 있으면, 그 ID를 기억
        if (fetched.thumbnailImagePath != null) {
          final idx = _existingPictures.indexWhere(
                (p) => p.thumbnailImagePath == fetched.thumbnailImagePath,
          );
          if (idx >= 0) {
            _selectedThumbnailId = _existingPictures[idx].picId;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 로딩 실패: ${e.toString()}';
      });
    }
  }

  /// 수정 모드 진입
  void _startEditing() {
    if (_post == null) return;
    _titleController.text = _post!.title ?? '';
    _contentController.text = _post!.content ?? '';
    _tagController.text = _post!.tag ?? '';
    setState(() {
      _isEditing = true;
    });
  }

  /// 수정 모드: 새 이미지 선택
  Future<void> _pickNewImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked != null && picked.isNotEmpty) {
        final existingPaths = {
          ..._newAttachedImages.map((f) => f.path),
          ..._existingPictures.map((p) => p.originImagePath ?? ''),
        };
        setState(() {
          for (var x in picked) {
            final f = File(x.path);
            if (!existingPaths.contains(f.path)) {
              _newAttachedImages.add(f);
            }
          }
        });
      }
    } catch (e) {
      print('이미지 피커 오류: $e');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  /// 수정 모드: 기존 서버 이미지를 삭제
  Future<void> _removeExistingPicture(final Picture pic) async {
    try {
      await PictureService.deletePicture(pic.picId!);
      setState(() {
        // 1) 기존 리스트에서 제거
        _existingPictures.removeWhere((p) => p.picId == pic.picId);

        // 2) 만약 썸네일 설정된 사진이었다면 해제
        if (_selectedThumbnailId == pic.picId) {
          _selectedThumbnailId = null;
        }

        // 3) _post 객체 내부 리스트에서도 제거
        _post?.pictureDTOList?.removeWhere((p) => p.picId == pic.picId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지가 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 삭제 실패: ${e.toString()}')),
      );
    }
  }

  /// 수정 모드: 로컬에서 고른 새 이미지를 서버에 업로드
  Future<void> _uploadNewImagesForEdit() async {
    if (_newAttachedImages.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      for (final file in _newAttachedImages) {
        final result = await PictureService.uploadImage(file);
        final pic = Picture.fromJson(result);
        _uploadedNewPictures.add(pic);

        // 만약 로컬 파일 hashCode를 썸네일 ID로 사용했다면 치환
        if (file.hashCode == _selectedThumbnailId) {
          _selectedThumbnailId = pic.picId;
        }
      }
      _newAttachedImages.clear();
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 업로드 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 수정 모드: 썸네일 선택
  void _selectThumbnail(int id) {
    setState(() {
      _selectedThumbnailId = id;
    });
  }

  /// 수정 저장
  Future<void> _saveEdit() async {
    if (_post == null) return;

    final updatedTitle = _titleController.text.trim();
    final updatedContent = _contentController.text.trim();
    final updatedTag = _tagController.text.trim();

    if (updatedTitle.isEmpty || updatedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1) 새로 고른 로컬 이미지를 서버에 업로드
      await _uploadNewImagesForEdit();

      // 2) 기존 서버 이미지 + 새로 업로드된 이미지 합치기
      final combinedPictures = <Picture>[];
      combinedPictures.addAll(_existingPictures);
      combinedPictures.addAll(_uploadedNewPictures);

      // 3) 선택된 썸네일 ID로부터 실제 thumbnailImagePath 찾아 저장
      String? newThumbnailPath;
      if (_selectedThumbnailId != null) {
        final selPic = combinedPictures.firstWhere(
              (p) => p.picId == _selectedThumbnailId,
          orElse: () => combinedPictures.first,
        );
        newThumbnailPath = selPic.thumbnailImagePath;
      }

      // 4) 새로운 Post 객체 생성 후 수정 요청
      final updatedPost = Post(
        postId: _post!.postId,
        userId: _post!.userId,
        userDTO: _post!.userDTO,
        title: updatedTitle,
        content: updatedContent,
        nickname: _post!.nickname,
        fileName: _post!.fileName,
        boardNo: _post!.boardNo,
        views: _post!.views,
        tag: updatedTag,
        thumbnailImagePath: newThumbnailPath,
        resizedImagePath: _post!.resizedImagePath,
        originImagePath: _post!.originImagePath,
        followers: _post!.followers,
        downloads: _post!.downloads,
        favoriteCnt: _post!.favoriteCnt,
        tradeDTO: _post!.tradeDTO,
        pictureDTOList: combinedPictures,
        profileImage: _post!.profileImage,
        replyCnt: _post!.replyCnt,
        regDate: _post!.regDate,
        modDate: _post!.modDate,
        liked: _post!.liked,
      );

      // 5) 서버로 실제 업데이트 요청 (void 반환)
      await PostService.updatePost(updatedPost);

      // 6) 업데이트가 끝나면, 최신 데이터를 다시 받아온다
      await _fetchPostDetail();

      // 7) 수정 모드 종료 및 로컬 상태 정리
      setState(() {
        _isEditing = false;
        _isLoading = false;
        _uploadedNewPictures.clear();
        _newAttachedImages.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 수정 실패: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 게시글 삭제
  Future<void> _deletePost() async {
    if (_post == null) return;

    final should = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (should != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await PostService.deletePost(_post!.postId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop(true);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제 실패: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _post != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.redAccent),
        ),
      )
          : _isEditing
          ? _buildEditView()
          : _buildDetailView(),
    );
  }

  /// 수정 모드 화면
  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 제목 입력 ─────────────────────────────────────
          TextField(
            controller: _titleController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '제목을 입력하세요',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),

          // ─── 태그 입력 ─────────────────────────────────────
          TextField(
            controller: _tagController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '태그를 입력하세요',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),

          // ─── 새 이미지 첨부 버튼 ───────────────────────────
          ElevatedButton.icon(
            onPressed: _isPickingImage ? null : _pickNewImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('이미지 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              disabledBackgroundColor: Colors.white10.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // ─── 기존+새로 고른 이미지 표시 및 썸네일/삭제 기능 ─────
          if (_existingPictures.isNotEmpty || _newAttachedImages.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 1) 서버에 있던 기존 이미지들
                ..._existingPictures.map((pic) {
                  final isSelected = pic.picId == _selectedThumbnailId;
                  String? path = pic.thumbnailImagePath ?? pic.resizedImagePath ?? pic.originImagePath;
                  Widget imageWidget;
                  if (path != null && path.isNotEmpty) {
                    imageWidget = Image.network(
                      "http://10.100.204.189:8080/ourlog/picture/display/$path",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    );
                  } else {
                    imageWidget = Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 40,
                      ),
                    );
                  }
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      // 썸네일 선택
                      GestureDetector(
                        onTap: () {
                          if (pic.picId != null) {
                            _selectThumbnail(pic.picId!);
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: imageWidget,
                        ),
                      ),
                      // 삭제 버튼 (X)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingPicture(pic),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // 썸네일 선택 표시
                      if (isSelected)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blueAccent,
                          ),
                        ),
                    ],
                  );
                }).toList(),

                // 2) 로컬에서 새로 고른 이미지들
                ..._newAttachedImages.map((file) {
                  final fakeId = file.hashCode;
                  final isSelected = fakeId == _selectedThumbnailId;
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
                                ? Border.all(color: Colors.blueAccent, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.check_circle, color: Colors.blueAccent),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ─── 내용 입력 ─────────────────────────────────────
          TextField(
            controller: _contentController,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              hintText: '내용을 입력하세요',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),

          // ─── 버튼 모음 (저장, 취소, 삭제) ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _saveEdit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('저장'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _newAttachedImages.clear();
                    _uploadedNewPictures.clear();
                    // _selectedThumbnailId는 그대로 둡니다.
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: _deletePost,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 상세 모드 화면
  Widget _buildDetailView() {
    final post = _post;
    if (post == null) {
      return const Center(
        child: Text(
          '게시글을 찾을 수 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // ① 썸네일로 지정된 경로가 있으면 그걸, 없으면 pictureDTOList 첫 번째를 사용
    String? thumbnailUrl;
    final allPics = post.pictureDTOList ?? [];
    if (post.thumbnailImagePath != null && post.thumbnailImagePath!.isNotEmpty) {
      thumbnailUrl = "http://10.100.204.189:8080/ourlog/picture/display/${post.thumbnailImagePath}";
    } else if (allPics.isNotEmpty) {
      final first = allPics.first;
      if (first.resizedImagePath != null && first.resizedImagePath!.isNotEmpty) {
        thumbnailUrl = "http://10.100.204.189:8080/ourlog/picture/display/${first.resizedImagePath}";
      } else if (first.thumbnailImagePath != null && first.thumbnailImagePath!.isNotEmpty) {
        thumbnailUrl = "http://10.100.204.189:8080/ourlog/picture/display/${first.thumbnailImagePath}";
      } else if (first.originImagePath != null && first.originImagePath!.isNotEmpty) {
        thumbnailUrl = "http://10.100.204.189:8080/ourlog/picture/display/${first.originImagePath}";
      } else {
        thumbnailUrl = null;
      }
    } else {
      thumbnailUrl = null;
    }

    // ② 이미지 개수에 따라 UI 결정
    final hasMultiple = allPics.length > 1;

    // ③ 이미지 섹션을 조건부로 만들어서, 이미지가 없으면 아예 빈 위젯으로 대체
    Widget imageSection;
    if (allPics.isEmpty) {
      // 이미지가 없으면 빈 위젯으로
      imageSection = const SizedBox.shrink();
    } else if (!hasMultiple && thumbnailUrl != null) {
      // 단일 이미지 보여주기: BoxFit.contain을 사용해서 전체 이미지가 잘리지 않고 보이도록 함
      imageSection = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailUrl,
          width: double.infinity,
          // height를 지정하지 않고, BoxFit.contain으로 전체가 보이게 함
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            width: double.infinity,
            color: Colors.grey[800],
            child: const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 50,
            ),
          ),
        ),
      );
    } else if (hasMultiple) {
      // 여러 이미지 보여주기 (가로 스크롤) - 썸네일 크기는 120×120 고정
      imageSection = SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: allPics.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, idx) {
            final pic = allPics[idx];
            String? imageUrl;
            if (pic.resizedImagePath != null && pic.resizedImagePath!.isNotEmpty) {
              imageUrl = "http://10.100.204.189:8080/ourlog/picture/display/${pic.resizedImagePath}";
            } else if (pic.thumbnailImagePath != null && pic.thumbnailImagePath!.isNotEmpty) {
              imageUrl = "http://10.100.204.189:8080/ourlog/picture/display/${pic.thumbnailImagePath}";
            } else if (pic.originImagePath != null && pic.originImagePath!.isNotEmpty) {
              imageUrl = "http://10.100.204.189:8080/ourlog/picture/display/${pic.originImagePath}";
            }
            if (imageUrl == null) {
              return Container(
                width: 120,
                height: 120,
                color: Colors.grey[800],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 40,
                ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      imageSection = const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ■ 제목
          Text(
            post.title ?? '제목 없음',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // ■ 이미지 영역 (조건부 렌더링)
          imageSection,
          if (allPics.isNotEmpty) const SizedBox(height: 16),

          // ■ 본문 내용
          Text(
            post.content ?? '내용 없음',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
