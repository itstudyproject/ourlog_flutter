import 'package:flutter/material.dart';
import '../../services/post/post_service.dart';
import '../../models/post/post.dart';

class CommunityPostListScreen extends StatefulWidget {
  final String? boardType;

  const CommunityPostListScreen({super.key, this.boardType});

  @override
  _CommunityPostListScreenState createState() => _CommunityPostListScreenState();
}

class _CommunityPostListScreenState extends State<CommunityPostListScreen> {
  List<Post> _posts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Map boardType string to boardNo integer
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

    final int? boardNo = _boardTypeToNo[widget.boardType];

    if (widget.boardType != null && boardNo == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '알 수 없는 게시판 종류입니다.';
      });
      return;
    }

    try {
      // Fetch posts using PostService, passing boardNo if available
      final List<Post> fetchedPosts = await PostService.getPosts(boardNo: boardNo);
      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 로딩 실패: ${e.toString()}';
      });
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
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                  : _posts.isEmpty
                      ? Center(child: Text('${_getBoardTitle()} 게시글이 없습니다.', style: const TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
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
                                  print('Tapped on post: ${post.title}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.title ?? '제목 없음',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '작성자: ${post.nickname ?? '알 수 없음'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '작성일: ${post.regDate ?? '날짜 없음'}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white70),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/post/register',
            arguments: {'boardType': widget.boardType},
          );
        },
        child: const Icon(Icons.add),
        tooltip: '새 게시글 작성',
      ),
    );
  }

  String _getBoardTitle() {
    switch (widget.boardType) {
      case 'news': return '새소식';
      case 'free': return '자유';
      case 'promotion': return '홍보';
      case 'request': return '요청';
      default: return '커뮤니티';
    }
  }
} 