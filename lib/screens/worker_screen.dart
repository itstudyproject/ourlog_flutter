import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ourlog/services/worker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class WorkerScreen extends StatefulWidget {
  final int userId; // 작가 id
  final int currentUserId; // 로그인한 유저 id

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
  List<Post> posts = [];
  int page = 1;
  final int size = 6;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchPosts();
    _scrollController.addListener(_onScroll);  // 리스너 등록
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    try {
      final profile = await WorkerService.fetchUserProfile(widget.userId);
      setState(() {
        nickname = profile['nickname'] ?? '';
        profileImageUrl = profile['thumbnailImagePath'] ?? '';
        isFollowing = profile['isFollowing'] ?? false;
      });
      print('[DEBUG] 프로필 이미지 URL: $profileImageUrl');
    } catch (e) {
      print('프로필 로딩 에러: $e');
    }
  }

  Future<void> fetchPosts() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    try {
      final postsData = await WorkerService.fetchUserPosts(widget.userId, page, size);

      final newPostsJson = postsData['pageResultDTO']?['dtoList'] ?? [];

      final newPosts = newPostsJson
          .map<Post>((json) => Post.fromJson(json))
          .where((post) => post.boardNo == 5)
          .toList();

      setState(() {
        posts.addAll(newPosts);
        page++;
        hasMore = !(postsData['pageResultDTO']?['last'] ?? true);
        isLoading = false;
      });
    } catch (e) {
      print('포스트 로딩 에러: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleFollow() async {
    try {
      await WorkerService.toggleFollow(widget.currentUserId, widget.userId, isFollowing);
      setState(() => isFollowing = !isFollowing);
    } catch (e) {
      print('팔로우 토글 에러: $e');
    }
  }

  Future<void> toggleLike(int postId, int index) async {
    try {
      final liked = await WorkerService.toggleLike(widget.currentUserId, postId);
      setState(() {
        posts[index].liked = liked;
        posts[index].favoriteCnt = (posts[index].favoriteCnt ?? 0) + (liked ? 1 : -1);
      });
    } catch (e) {
      print('좋아요 토글 에러: $e');
    }
  }

  Future<Uint8List?> fetchImageBytes(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.startsWith('image/')) {
          return response.bodyBytes;
        } else {
          print('[DEBUG] 이미지 아님: content-type=$contentType');
          return null;
        }
      } else {
        print('[DEBUG] 이미지 요청 실패: ${response.statusCode}, URL: $imageUrl');
        return null;
      }
    } catch (e) {
      print('[DEBUG] 이미지 요청 예외 발생: $e');
      return null;
    }
  }

  // ★ 여기가 추가된 부분 ★
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      fetchPosts();
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
          // 작가 프로필 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[800],
                  child: profileImageUrl.isNotEmpty
                      ? FutureBuilder<Uint8List?>(
                    future: fetchImageBytes(profileImageUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return const Icon(Icons.person, size: 40, color: Colors.white);
                      } else {
                        return ClipOval(
                          child: Image.memory(
                            snapshot.data!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                    },
                  )
                      : const Icon(Icons.person, size: 40, color: Colors.white),
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

          // 작품 목록 그리드
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final imageUrl = post.getImageUrl();
                final title = post.title;
                final likesCount = post.favoriteCnt;
                final liked = post.liked;

                return Card(
                  color: Colors.grey[900],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: imageUrl.isNotEmpty
                            ? FutureBuilder<Uint8List?>(
                          future: fetchImageBytes(imageUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError || snapshot.data == null) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.white),
                              );
                            } else {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            }
                          },
                        )
                            : Container(
                          color: Colors.grey[700],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          post.title ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$likesCount 좋아요',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            IconButton(
                              onPressed: () {
                                if (post.postId != null) {
                                  toggleLike(post.postId!, index);
                                }
                              },
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
