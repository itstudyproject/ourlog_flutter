// lib/screens/post/community_post_list_screen.dart

import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../models/post.dart';
import '../../models/picture.dart';
import 'community_post_detail_screen.dart';

class CommunityPostListScreen extends StatefulWidget {
  final String? boardType;

  const CommunityPostListScreen({Key? key, this.boardType}) : super(key: key);

  @override
  _CommunityPostListScreenState createState() =>
      _CommunityPostListScreenState();
}

class _CommunityPostListScreenState extends State<CommunityPostListScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  /// Header 위젯에서 넘기는 boardType(예: 'news', 'free', 'promotion', 'request')을
  /// 실제 각 게시판 번호(boardNo)로 매핑하는 맵
  final Map<String, int> _boardTypeToNo = {
    'news': 1,
    'free': 2,
    'promotion': 3,
    'request': 4,
  };

  /// Android 에뮬레이터에서 개발 PC의 localhost(127.0.0.1)에 접근할 때 쓰는 주소.
  /// 실제 물리 디바이스에서는 "http://192.168.xxx.xxx:8080" 등으로 바꿔 주세요.
  static const String _imageBaseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final boardNo = widget.boardType != null
        ? _boardTypeToNo[widget.boardType]
        : null;

    if (widget.boardType != null && boardNo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '알 수 없는 게시판 종류입니다.';
      });
      return;
    }

    try {
      final fetched = await PostService.getPosts(boardNo: boardNo);
      setState(() {
        _posts = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 로딩 실패: ${e.toString()}';
      });
    }
  }

  String _getBoardTitle() {
    switch (widget.boardType) {
      case 'news':
        return '새소식';
      case 'free':
        return '자유';
      case 'promotion':
        return '홍보';
      case 'request':
        return '요청';
      default:
        return '커뮤니티';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${_getBoardTitle()} 게시판'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          )
              : _errorMessage.isNotEmpty
              ? Center(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.redAccent),
            ),
          )
              : _posts.isEmpty
              ? Center(
            child: Text(
              '${_getBoardTitle()} 게시글이 없습니다.',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16),
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchPosts,
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (ctx, index) {
                final post = _posts[index];

                // ───────────────────────────────────────────
                // ① Picture 리스트에서 사용할 이미지 경로(상대 경로)를 결정
                //    우선순위:
                //      1) thumbnailImagePath (썸네일 상대 경로)
                //      2) originImagePath    (원본 이미지 상대 경로)
                //      3) null (이미지 없음)
                // ───────────────────────────────────────────
                String? relativePath;
                if (post.pictureDTOList != null &&
                    post.pictureDTOList!.isNotEmpty) {
                  final Picture firstPic = post.pictureDTOList!.first;
                  if (firstPic.thumbnailImagePath != null &&
                      firstPic.thumbnailImagePath!.isNotEmpty) {
                    relativePath = firstPic.thumbnailImagePath;
                  } else if (firstPic.originImagePath != null &&
                      firstPic.originImagePath!.isNotEmpty) {
                    relativePath = firstPic.originImagePath;
                  }
                }

                // ───────────────────────────────────────────
                // ② 상대 경로 → 절대 URL 변환
                //    "null"이 아닌 경우에만 URL 조합
                // ───────────────────────────────────────────
                final String? thumbnailUrl = (relativePath != null)
                    ? '$_imageBaseUrl/ourlog/picture/display/$relativePath'
                    : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommunityPostDetailScreen(
                                postId: post.postId!,
                              ),
                        ),
                      ).then((deletedOrUpdated) {
                        if (deletedOrUpdated == true) {
                          _fetchPosts();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // ─── (왼쪽) 텍스트 정보 영역 ───
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                // 제목
                                Text(
                                  post.title ?? '제목 없음',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // 작성자
                                Text(
                                  '작성자: ${post.nickname ?? '알 수 없음'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // 작성일
                                Text(
                                  '작성일: ${post.regDate != null ? post.regDate!.toLocal().toString().split(' ')[0] : '날짜 없음'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ─── (오른쪽) 썸네일이 있을 때만 보여주기 ───
                          if (thumbnailUrl != null) ...[
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(6),
                              child: Image.network(
                                thumbnailUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, _) {
                                  // 이미지 로딩 실패 시 대체 위젯
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/post/register',
            arguments: {'boardType': widget.boardType},
          ).then((_) {
            _fetchPosts();
          });
        },
        child: const Icon(Icons.add),
        tooltip: '새 게시글 작성',
      ),
    );
  }
}
