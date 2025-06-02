import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../models/post.dart';
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

  // boardType 문자열을 boardNo 정수로 매핑
  final Map<String, int> _boardTypeToNo = {
    'news': 1,
    'free': 2,
    'promotion': 3,
    'request': 4,
  };

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
                        // 상세 화면에서 삭제(delete) 또는 수정(update) 후 돌아올 때,
                        // true가 전달되면 목록을 다시 로드합니다.
                        if (deletedOrUpdated == true) {
                          _fetchPosts();
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '작성자: ${post.nickname ?? '알 수 없음'}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '작성일: ${post.regDate != null ? post.regDate!.toLocal().toString().split(' ')[0] : '날짜 없음'}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70),
                          ),
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
            // 게시글 등록 화면에서 돌아오면 다시 목록을 불러옵니다.
            _fetchPosts();
          });
        },
        child: const Icon(Icons.add),
        tooltip: '새 게시글 작성',
      ),
    );
  }
}
