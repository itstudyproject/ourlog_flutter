// lib/screens/my_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/my_post_service.dart';
import '../models/post.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final MyPostService _service = MyPostService();
  bool _loading = true;
  String? _error;
  List<Post>? _posts;
  int? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId;
    _token = auth.token;
    debugPrint('▶ MyPostsScreen initState: userId=$_userId, token=$_token');
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    if (_userId == null || _token == null) {
      debugPrint('⚠️ _loadMyPosts: userId 혹은 token이 null입니다');
      return; // 필요 시 로그인 화면으로 리다이렉트
    }

    setState(() => _loading = true);
    debugPrint('▶ MyPostsScreen: HTTP 요청 시작 userId=$_userId');

    try {
      // 수정된 경로를 사용하는 fetchMyPosts 호출
      final list = await _service.fetchMyPosts(_userId!, _token!);
      debugPrint('✅ MyPostsScreen: fetchMyPosts 응답받음 (개수=${list.length})');
      setState(() {
        _posts = list;
        _error = null;
      });
    } catch (e) {
      debugPrint('❌ MyPostsScreen: fetchMyPosts 오류: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePost(int postId) async {
    if (_token == null) {
      debugPrint('⚠️ _deletePost: token이 null입니다');
      return;
    }

    try {
      // 삭제 엔드포인트도 /profile/posts/{postId}로 맞춰야 합니다.
      await _service.deletePost(postId, _token!);
      debugPrint('✅ MyPostsScreen: deletePost 성공, postId=$postId');
      _loadMyPosts();
    } catch (e) {
      debugPrint('❌ MyPostsScreen: deletePost 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('내 글'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final List<Post> posts = _posts!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 중앙 타이틀 + 주황 밑줄
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF8C147),
                width: 2,
              ),
            ),
          ),
          child: const Text(
            '내 글',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 비었으면 안내문, 아니면 리스트
        Expanded(
          child: posts.isEmpty
              ? const Center(
            child: Text(
              '작성한 글이 없습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 15),
            itemBuilder: (context, i) => _buildPostItem(posts[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildPostItem(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/art/${post.postId}');
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 썸네일
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[800],
                image: post.thumbnailImagePath != null
                    ? DecorationImage(
                  image: NetworkImage(
                    'http://10.100.204.144:8080${post.thumbnailImagePath}',
                    headers: {
                      'Authorization':
                      'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
                    },
                  ),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: post.thumbnailImagePath == null
                  ? const Icon(
                Icons.image_not_supported,
                color: Colors.white24,
                size: 32,
              )
                  : null,
            ),
            const SizedBox(width: 15),

            // 작품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? '제목 없음',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '작성일: ${_formatDate(post!.regDate)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '좋아요: ${post.favoriteCnt}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // 액션 버튼
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/art/${post.postId}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('자세히 보기'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _deletePost(post.postId!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('삭제하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return '${date?.year.toString().padLeft(4, '0')}-'
        '${date?.month.toString().padLeft(2, '0')}-'
        '${date?.day.toString().padLeft(2, '0')}';
  }
}
