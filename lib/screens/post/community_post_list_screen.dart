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

  // 카테고리 선택 상태
  late String _selectedBoardType;

  // 카테고리 리스트
  final List<Map<String, String>> _categories = [
    {'value': 'news', 'label': '새소식'},
    {'value': 'free', 'label': '자유게시판'},
    {'value': 'promotion', 'label': '홍보게시판'},
    {'value': 'request', 'label': '요청게시판'},
  ];

  // boardType -> boardNo 매핑
  final Map<String, int> _boardTypeToNo = {
    'news': 1,
    'free': 2,
    'promotion': 3,
    'request': 4,
  };

  static const String _imageBaseUrl = 'http://192.168.219.102:8080';

  @override
  void initState() {
    super.initState();
    _selectedBoardType = widget.boardType ?? _categories.first['value']!;
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final boardNo = _boardTypeToNo[_selectedBoardType];

    try {
      final fetched = await PostService.getPosts(boardNo: boardNo);
      setState(() {
        _posts = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 로딩 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedBoardType,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            items: _categories
                .map((c) => DropdownMenuItem(
              value: c['value'],
              child: Text(c['label']!),
            ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() { _selectedBoardType = value; });
              _fetchPosts();
            },
          ),
        ),
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
              '${_categories.firstWhere((c) => c['value'] == _selectedBoardType)['label']} 게시글이 없습니다.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          )
              : RefreshIndicator(
            onRefresh: _fetchPosts,
            child: ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (ctx, index) {
                final post = _posts[index];
                String? relativePath;
                if (post.pictureDTOList != null &&
                    post.pictureDTOList!.isNotEmpty) {
                  final pic = post.pictureDTOList!.first;
                  relativePath = pic.thumbnailImagePath?.isNotEmpty == true
                      ? pic.thumbnailImagePath
                      : pic.originImagePath;
                }
                final thumbnailUrl = relativePath != null
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
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityPostDetailScreen(
                            postId: post.postId!,
                          ),
                        ),
                      );
                      if (updated == true) _fetchPosts();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title ?? '제목 없음',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '작성자: ${post.nickname ?? '알 수 없음'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
        onPressed: () async {
          await Navigator.pushNamed(
            context,
            '/post/register',
            arguments: {'boardType': _selectedBoardType},
          );
          _fetchPosts();
        },
        child: const Icon(Icons.add),
        tooltip: '새 게시글 작성',
      ),
    );
  }
}
