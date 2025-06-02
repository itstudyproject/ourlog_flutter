import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ourlog/services/worker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'package:provider/provider.dart'; // Provider 사용을 위한 패키지
import 'package:ourlog/providers/chat_provider.dart'; // ChatProvider 경로 확인!

class WorkerScreen extends StatefulWidget {
  final int userId;
  final int currentUserId;

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
  int followCnt = 0;
  int followingCnt = 0;
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
    _scrollController.addListener(_onScroll);
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
        followCnt = profile['followerCount'] ?? 0;
        followingCnt = profile['followingCount'] ?? 0;
      });
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
          .where((post) => post.boardNo == 5 && post.userId == widget.userId)
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
      setState(() {
        isFollowing = !isFollowing;
        if (isFollowing) {
          followCnt += 1; // 팔로우 했을 때 +1
        } else {
          followCnt = (followCnt > 0) ? followCnt - 1 : 0; // 언팔로우 했을 때 -1 (0 미만 방지)
        }
      });
    } catch (e) {
      print('팔로우 토글 에러: $e');
    }
  }
  Future<void> toggleLike(int postId, int index) async {
    final wasLiked = posts[index].liked ?? false;
    final wasCount = posts[index].favoriteCnt ?? 0;

    setState(() {
      posts[index].liked = !wasLiked;
      posts[index].favoriteCnt = !wasLiked ? wasCount + 1 : (wasCount > 0 ? wasCount - 1 : 0);
    });

    try {
      final isLikedNow = await WorkerService.toggleLike(widget.currentUserId, postId);
      setState(() {
        posts[index].liked = isLikedNow;
        posts[index].favoriteCnt = isLikedNow
            ? (!wasLiked ? wasCount + 1 : wasCount)
            : (wasLiked ? (wasCount > 0 ? wasCount - 1 : 0) : wasCount);
      });
    } catch (e) {
      print('좋아요 토글 에러: $e');
      setState(() {
        posts[index].liked = wasLiked;
        posts[index].favoriteCnt = wasCount;
      });
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

      if (response.statusCode == 200 &&
          response.headers['content-type']?.startsWith('image/') == true) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('이미지 요청 실패: $e');
    }
    return null;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
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
          const SizedBox(height: 16), // ✅ AppBar 아래 여백

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 여백
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 👤 프로필 이미지
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
                    // 🔤 닉네임 + 팔로워/팔로잉
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                nickname,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                children: [
                                  Row(
                                    children: const [
                                      Text('팔로우', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                      SizedBox(width: 16),
                                      Text('팔로잉', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '$followCnt',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Text(
                                        '$followingCnt',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (widget.userId != widget.currentUserId) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: toggleFollow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: Text(isFollowing ? '언팔로우' : '팔로우'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                          final prefs = await SharedPreferences.getInstance();
                          final jwtToken = prefs.getString('token');

                          if (jwtToken == null || jwtToken.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('채팅을 시작하려면 로그인하세요.')),
                            );
                            return;
                          }

                          final channel = await chatProvider.create1to1Channel(widget.userId.toString());

                          if (channel != null) {
                            Navigator.pushNamed(context, '/chat', arguments: channel);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('채팅 채널을 생성할 수 없습니다.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8C147),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('채팅창'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16), // ✅ 프로필과 Divider 사이 여백
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 21.0),
            child: Divider(color: Colors.white, height: 1),
          ),

          const SizedBox(height: 16),

          // 작품 목록
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final imageUrl = post.getImageUrl();
                final title = post.title;
                final likesCount = post.favoriteCnt ?? 0;
                final liked = post.liked ?? false;

                return GestureDetector(
                  onTap: () {
                    if (post.postId != null) {
                      Navigator.pushNamed(context, '/postDetail', arguments: post.postId);
                    }
                  },
                  child: Card(
                    color: Colors.grey[900],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              imageUrl.isNotEmpty
                                  ? FutureBuilder<Uint8List?>(
                                future: fetchImageBytes(imageUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (snapshot.hasError || snapshot.data == null) {
                                    return _placeholderImage();
                                  } else {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    );
                                  }
                                },
                              )
                                  : _placeholderImage(),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => toggleLike(post.postId!, index),
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 80), // ✅ 너비 제한 추가
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          liked ? '🧡' : '🤍',
                                          style: const TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis, // ✅ 이모지가 넘칠 경우 방지
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible( // ✅ 긴 숫자 overflow 방지
                                          child: Text(
                                            '$likesCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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

  Widget _placeholderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.grey[700],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }
}
