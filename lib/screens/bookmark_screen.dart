// lib/screens/bookmark_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/favorite_service.dart';
import '../models/favorite.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final _service = FavoriteService();
  bool _loading = true;
  String? _error;
  List<Favorite>? _favorites;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      setState(() {
        _error = '로그인이 필요합니다.';
        _loading = false;
      });
      return;
    }
    try {
      final list = await _service.fetchFavorites(userId);
      setState(() {
        _favorites = list;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('북마크'),
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
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    final favs = _favorites!;

    // ► 여기서부터는 비었든 안 비었든 헤더를 먼저 그립니다
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 중앙 타이틀 + 주황 밑줄 ────────────────────
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF8C147), // 주황색
                width: 2,                 // 두께 2
              ),
            ),
          ),
          child: const Text(
            '북마크',
            style: TextStyle(
              color: Colors.white,       // 흰색 글자
              fontSize: 16,              // 크기 24
              fontWeight: FontWeight.w600, // 반굵기
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ─── 비었으면 안내문, 아니면 리스트 ────────────
        Expanded(
          child: favs.isEmpty
              ? const Center(
            child: Text(
              '북마크한 작품이 없습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : ListView.separated(
            itemCount: favs.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 15),
            itemBuilder: (context, i) =>
                _buildFavoriteItem(favs[i]),
          ),
        ),
      ],
    );
  }

  // ─── 리스트 ────────────────────
  //       Expanded(
  //         child: ListView.separated(
  //           itemCount: favs.length,
  //           separatorBuilder: (_, __) => const SizedBox(height: 15),
  //           itemBuilder: (context, i) => _buildFavoriteItem(favs[i]),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildFavoriteItem(Favorite fav) {
    final post = fav.post;
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
                image: DecorationImage(
                  image: AssetImage("assets/images/mypage.png"),
                  fit: BoxFit.cover,
                ),
              ),
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
                    '작가: ${post.nickname ?? '알 수 없음'}',
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
                    // 북마크 해제 API 호출
                    await _service.deleteFavorite(fav.favoriteId);
                    // 다시 로드
                    _loadFavorites();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8C147),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('북마크 해제'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}