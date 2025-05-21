import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class WorkerScreen extends StatefulWidget {
  final int userId;

  const WorkerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  late Future<UserProfile> profileFuture;
  List<Post> posts = [];
  List<LikeStatus> likes = [];
  int currentPage = 1;
  final int itemsPerPage = 4;

  int loggedInUserId = 0;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    profileFuture = fetchUserProfile(widget.userId); // 먼저 초기화
    _initialize(); // 그 다음 나머지 작업
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getInt('userId') ?? 0;

    profileFuture = fetchUserProfile(widget.userId);
    await loadPosts();
    setState(() {});
  }

  Future<void> loadPosts() async {
    try {
      final fetchedPosts = await fetchUserPosts(widget.userId);
      posts = fetchedPosts;

      final likeStatuses = await Future.wait(posts.map((post) async {
        final status = await fetchLikeStatus(loggedInUserId, post.id);
        return status;
      }));

      likes = likeStatuses.cast<LikeStatus>();
      setState(() {});
    } catch (e) {
      print("❌ 게시물 또는 좋아요 로딩 실패: $e");
    }
  }

  void _handleLikeToggle(int index) async {
    try {
      final toggledLike = await toggleLike(loggedInUserId, posts[index].id);

      setState(() {
        likes[index] = LikeStatus(
          liked: toggledLike,
          count: toggledLike ? likes[index].count + 1 : likes[index].count - 1,
        );
      });
    } catch (e) {
      print("❌ 좋아요 토글 실패: $e");
    }
  }

  void _handleFollowToggle(UserProfile profile) async {
    try {
      final newStatus = await toggleFollow(loggedInUserId, widget.userId);
      setState(() {
        isFollowing = newStatus;
        profile.followingCnt += newStatus ? 1 : -1;
      });
    } catch (e) {
      print("❌ 팔로우 실패: $e");
    }
  }

  void _navigateToChat() {
    Navigator.pushNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("작가 페이지"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserProfile>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("프로필을 불러올 수 없습니다."));
          }

          final profile = snapshot.data!;
          isFollowing = profile.isFollowing;

          return Column(
            children: [
              _buildHeader(profile),
              Expanded(child: _buildPostGrid()),
              _buildPagination(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: CachedNetworkImageProvider(
              profile.thumbnailImagePath.isNotEmpty
                  ? profile.thumbnailImagePath
                  : 'https://via.placeholder.com/150',
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.nickname,
                    style: const TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStat("팔로우", profile.followCnt),
                    const SizedBox(width: 20),
                    _buildStat("팔로잉", profile.followingCnt),
                  ],
                ),
                if (loggedInUserId != widget.userId)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleFollowToggle(profile),
                        child: Text(isFollowing ? "팔로잉" : "팔로우"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _navigateToChat,
                        child: const Text("채팅"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text("$count",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildPostGrid() {
    final pagedPosts = posts.skip((currentPage - 1) * itemsPerPage).take(itemsPerPage).toList();
    final pagedLikes = likes.skip((currentPage - 1) * itemsPerPage).take(itemsPerPage).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pagedPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = pagedPosts[index];
        final like = pagedLikes[index];

        return GestureDetector(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: post.image,
                      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _handleLikeToggle(index + (currentPage - 1) * itemsPerPage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "♥ ${like.count}",
                            style: TextStyle(
                              color: like.liked ? Colors.redAccent : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(post.title, style: const TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    final totalPages = (posts.length / itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return TextButton(
          onPressed: () {
            setState(() {
              currentPage = page;
            });
          },
          child: Text(
            "$page",
            style: TextStyle(
              color: currentPage == page ? Colors.amber : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }
}
