import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ourlog/services/worker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import 'package:provider/provider.dart';
import 'package:ourlog/providers/chat_provider.dart';

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
      final postsData =
      await WorkerService.fetchUserPosts(widget.userId, page, size);
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
      await WorkerService.toggleFollow(
          widget.currentUserId, widget.userId, isFollowing);
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
    final oldLiked = posts[index].liked ?? false;
    final oldCount = posts[index].favoriteCnt ?? 0;

    try {
      final isLikedNow = await WorkerService.toggleLike(widget.currentUserId, postId);

      setState(() {
        posts[index].liked = isLikedNow;
        posts[index].favoriteCnt = isLikedNow
            ? oldCount + (oldLiked ? 0 : 1) // 좋아요가 새로 눌렸다면 +1
            : oldCount - (oldLiked ? 1 : 0); // 좋아요가 취소됐다면 -1
      });
    } catch (e) {
      print('좋아요 토글 에러: $e');
      setState(() {
        posts[index].liked = oldLiked;
        posts[index].favoriteCnt = oldCount;
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isLoading &&
        hasMore) {
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
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 👤 프로필 이미지 (고정 크기)
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[800],
                      child: profileImageUrl.isNotEmpty
                          ? FutureBuilder<Uint8List?>(
                        future: fetchImageBytes(profileImageUrl),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator(
                                color: Colors.white);
                          } else if (snapshot.hasError ||
                              snapshot.data == null) {
                            return const Icon(Icons.person,
                                size: 40, color: Colors.white);
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
                    const SizedBox(width: 16), // 프로필 이미지와 다음 요소 사이 간격

                    // 🔤 닉네임 + 팔로워/팔로잉 (남은 공간의 일부를 차지)
                    // 이 부분을 Expanded로 감싸서 남은 공간을 유연하게 사용하도록 합니다.
                    Expanded(
                      flex: 3, // 이 부분이 더 많은 공간을 차지하도록 flex 값을 줍니다.
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            // 닉네임과 팔로워/팔로잉 숫자를 포함하는 Row
                            children: [
                              Flexible( // 닉네임이 길어질 때 오버플로우 방지
                                child: Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis, // 텍스트가 길어지면 ...으로 표시
                                ),
                              ),
                              const SizedBox(width: 16), // 닉네임과 팔로우/팔로잉 텍스트 사이 간격
                              // 팔로우/팔로잉 카운트 그룹 (고정된 공간을 가집니다)
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

                    // 팔로우/채팅 버튼 (남은 공간의 일부를 차지)
                    if (widget.userId != widget.currentUserId) ...[
                      const SizedBox(width: 8), // 프로필 정보와 버튼 사이 간격
                      Expanded( // 이 부분도 Expanded로 감싸서 남은 공간을 유연하게 사용
                        flex: 2, // 닉네임/카운트 부분보다 적은 공간을 차지하도록 flex 값을 줍니다.
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end, // 버튼을 오른쪽으로 정렬
                          children: [
                            Flexible( // 버튼의 텍스트가 길어질 경우
                              child: OutlinedButton(
                                onPressed: toggleFollow,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(horizontal: 8), // 패딩 줄이기
                                  textStyle: const TextStyle(fontSize: 12), // 폰트 크기 줄이기
                                ),
                                child: Text(
                                  isFollowing ? '언팔로우' : '팔로우',
                                  overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 방지
                                ),
                              ),
                            ),
                            const SizedBox(width: 4), // 버튼들 사이 간격 줄이기
                            Flexible( // 버튼의 텍스트가 길어질 경우
                              child: ElevatedButton(
                                onPressed: () async {
                                  final chatProvider =
                                  Provider.of<ChatProvider>(context, listen: false);
                                  final prefs = await SharedPreferences.getInstance();
                                  final jwtToken = prefs.getString('token');

                                  if (jwtToken == null || jwtToken.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('채팅을 시작하려면 로그인하세요.')),
                                    );
                                    return;
                                  }

                                  final channel = await chatProvider
                                      .create1to1Channel(widget.userId.toString());

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
                                  padding: const EdgeInsets.symmetric(horizontal: 8), // 패딩 줄이기
                                  textStyle: const TextStyle(fontSize: 12), // 폰트 크기 줄이기
                                ),
                                child: const Text(
                                  '채팅창',
                                  overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 방지
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
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
                childAspectRatio: 0.8, // 이전과 동일하게 유지
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return isLoading
                      ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                      : const SizedBox.shrink();
                }
                final post = posts[index];
                final imageUrl = post.getImageUrl();
                final title = post.title;
                final likesCount = post.favoriteCnt ?? 0;
                final liked = post.liked ?? false;

                return GestureDetector(
                  onTap: () {
                    if (post.postId != null) {
                      Navigator.pushNamed(context, '/postDetail',
                          arguments: post.postId);
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError ||
                                      snapshot.data == null) {
                                    return _placeholderImage();
                                  } else {
                                    return ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12),
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
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => toggleLike(post.postId!, index),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                        maxWidth: 80),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '$likesCount',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14),
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
