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
  State<WorkerScreen> createState() => _WorkerScreenState();
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
  ScrollController _scrollController = ScrollController();

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

  // 프로필 정보 가져오기 - 수정된 함수
  Future<void> fetchProfile() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/ourlog/profile/get/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      print("프로필 응답: ${response.body}"); // 디버깅용 출력
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
    setState(() {
      isLoading = true;
    });

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
    }
    setState(() {
      isLoading = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
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
      setState(() {
        isFollowing = !isFollowing;
      });
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
      appBar: AppBar(title: Text('$nickname의 페이지')),
      body: Column(
        children: [
          // 작가 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(Icons.person, size: 40)
                      : null,
                ),
                SizedBox(width: 16),
                Text(nickname, style: TextStyle(fontSize: 20)),
                Spacer(),
                ElevatedButton(
                  onPressed: toggleFollow,
                  child: Text(isFollowing ? '언팔로우' : '팔로우'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                  child: Text('채팅창'),
                ),
              ],
            ),
          ),

          // 작품 목록
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 두 개씩 정렬
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return Center(child: CircularProgressIndicator());
                }

                final post = posts[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          post['imagePath'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(post['title'] ?? '제목 없음',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                            onPressed: () => toggleLike(post['postId'], index),
                          ),
                          Text('${post['favoriteCnt']}'),
                          SizedBox(width: 8),
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
