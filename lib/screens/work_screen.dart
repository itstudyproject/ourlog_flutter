import 'package:flutter/material.dart';
import 'package:ourlog/models/post.dart';
import 'package:ourlog/models/user_profile.dart';
import 'package:ourlog/services/api_service.dart'; // ApiService가 있다고 가정
import 'package:ourlog/widgets/post_card.dart'; // PostCard는 게시글 카드 위젯

class WorkScreen extends StatefulWidget {
  final String writerId;
  final String currentUserId;

  const WorkScreen({
    required this.writerId,
    required this.currentUserId,
    super.key,
  });

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  late Future<UserProfile> writerProfile;
  late Future<List<Post>> writerPosts;
  bool isFollowing = false;

  int followCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    writerProfile = _loadProfile();
    writerPosts = ApiService.getUserPosts(widget.writerId);
    _checkFollowing();
  }

  Future<UserProfile> _loadProfile() async {
    final profile = await ApiService.getUserProfile(widget.writerId);
    setState(() {
      followCount = profile.followCount ?? 0;
      followingCount = profile.followingCount ?? 0;
    });
    return profile;
  }

  void _checkFollowing() async {
    final following = await ApiService.isFollowing(widget.currentUserId, widget.writerId);
    setState(() {
      isFollowing = following;
    });
  }

  void _toggleFollow() async {
    if (isFollowing) {
      await ApiService.unfollowUser(widget.currentUserId, widget.writerId);
      setState(() => followCount--);
    } else {
      await ApiService.followUser(widget.currentUserId, widget.writerId);
      setState(() => followCount++);
    }
    _checkFollowing();
  }

  void _openChat() {
    Navigator.pushNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('작가 페이지'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<UserProfile>(
        future: writerProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('작가 정보를 불러오지 못했습니다.', style: TextStyle(color: Colors.white)),
            );
          }

          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(user),
                const Divider(color: Colors.white24),
                Expanded(child: _buildPostList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(user.thumbnailImagePath),
          radius: 50,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.nickname, style: const TextStyle(fontSize: 24, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStat("팔로워", followCount),
                  const SizedBox(width: 20),
                  _buildStat("팔로잉", followingCount),
                ],
              ),
            ],
          ),
        ),
        if (widget.writerId != widget.currentUserId)
          Column(
            children: [
              ElevatedButton(
                onPressed: _toggleFollow,
                child: Text(isFollowing ? '팔로잉' : '팔로우'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _openChat,
                child: const Text('채팅'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPostList() {
    return FutureBuilder<List<Post>>(
      future: writerPosts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('게시글이 없습니다.', style: TextStyle(color: Colors.white70)),
          );
        }

        final posts = snapshot.data!
            .where((post) => post.boardNo == 5) // 특정 board 번호 필터링
            .toList();

        return GridView.builder(
          itemCount: posts.length,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(
              post: post,
              imageUrls: post.imageList ?? [],
              isLiked: post.likes.contains(widget.currentUserId),
            );
          },
        );
      },
    );
  }
}
