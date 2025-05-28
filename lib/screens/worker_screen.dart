import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkerScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;

  const WorkerScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
  });

  @override
  _WorkerScreenState createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  String nickname = '';
  String profileImageUrl = '';
  bool isFollowing = false;
  List<dynamic> posts = [];
  int page = 0;
  final int size = 6;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/ourlog/profile/get/${widget.userId}'),
    );

    print('응답 상태: ${response.statusCode}');
    print('응답 바디: ${response.body}');


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        nickname = data['nickname'] ?? '';
        profileImageUrl = data['thumbnailImagePath'] ?? '';
        isFollowing = data['isFollowing'] ?? false;
      });
    } else {
      print("프로필 정보를 불러오는데 실패했습니다. 상태 코드: ${response.statusCode}");
    }
  }

  Future<void> fetchPosts() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse(
          'http://localhost:8080/api/posts/user/${widget.userId}?page=$page&size=$size'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newPosts = data['content'];
      setState(() {
        posts.addAll(newPosts);
        page++;
        hasMore = !data['last'];
      });



    // ✅ 여기에 출력
    print('불러온 포스트 수: ${posts.length}');
  } else {
  print('포스트 로딩 실패: ${response.statusCode}');
  }


    setState(() => isLoading = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      fetchPosts();
    }
  }

  Future<void> toggleFollow() async {
    final url = isFollowing
        ? 'http://localhost:8080/api/unfollow'
        : 'http://localhost:8080/api/follow';

    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode({'followingUserId': widget.userId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() => isFollowing = !isFollowing);
    }
  }

  Future<void> toggleLike(int postId, int index) async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/like/$postId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        posts[index]['liked'] = !posts[index]['liked'];
        posts[index]['favoriteCnt'] += posts[index]['liked'] ? 1 : -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('$nickname의 페이지'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ─── 작가 프로필 ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  nickname,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: toggleFollow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: Text(isFollowing ? '언팔로우' : '팔로우'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8C147),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('채팅창'),
                ),
              ],
            ),
          ),

          // ─── 작품 목록 ────────────────────────────────
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final post = posts[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 썸네일 이미지
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          child: post['imagePath'] != null
                              ? Image.network(
                            post['imagePath'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image,
                                color: Colors.white),
                          )
                              : const Icon(Icons.image, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          post['title'] ?? '제목 없음',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              post['liked']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                toggleLike(post['postId'], index),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${post['favoriteCnt']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
