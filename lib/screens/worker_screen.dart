import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

class WorkerScreen extends StatefulWidget {
  final int userId;         // 작가의 userId
  final int currentUserId;  // 로그인한 사용자 ID

  const WorkerScreen({
    Key? key,
    required this.userId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<WorkerScreen> createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  late Future<UserProfile> futureProfile;

  @override
  void initState() {
    super.initState();
    futureProfile = fetchUserProfile(widget.userId);
  }

  Future<void> handleToggleFollow(UserProfile profile) async {
    try {
      final isFollowing = await toggleFollow(widget.currentUserId, widget.userId);

      // 팔로우 상태 변경 후 프로필 정보 갱신
      futureProfile = fetchUserProfile(widget.userId);
      setState(() {});  // FutureBuilder가 다시 동작하도록 갱신
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팔로우 처리 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('작가 페이지')),
      body: FutureBuilder<UserProfile>(
        future: futureProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('데이터 없음'));
          }

          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey[100],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(profile.thumbnailImagePath),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.nickname,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('팔로워 ${profile.followCnt}명'),
                                const SizedBox(width: 12),
                                Text('팔로잉 ${profile.followingCnt}명'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(profile.introduction),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => handleToggleFollow(profile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: profile.isFollowing ? Colors.grey : Colors.blue,
                              ),
                              child: Text(profile.isFollowing ? '팔로잉' : '팔로우'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // TODO: 작품 카드 목록 추가
              ],
            ),
          );
        },
      ),
    );
  }
}
