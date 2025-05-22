// lib/screens/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _service = ProfileService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    print('>> fetching profile for $userId');
    try {
    print('>> fetching profile for $userId');
      final profile = await _service.fetchProfile(userId);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (e) {
      // TODO: 에러 처리 (예: SnackBar)
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        body: Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('OurLog'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드
            Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                        _profile!.thumbnailImagePath,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile!.nickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '팔로워: ${_profile!.followCnt}  팔로잉: ${_profile!.followingCnt}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/mypage/edit'),
                                child: const Text('프로필수정'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/mypage/account/edit'),
                                child: const Text('회원정보수정'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pushNamed(
                                    context, '/mypage/account/delete'),
                                child: const Text('회원탈퇴'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 메뉴
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('메뉴',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _menuButton(context, '구매/입찰목록',
                '/mypage/purchase-bid'),
            _menuButton(context, '판매목록/현황', '/mypage/sale'),
            _menuButton(context, '북마크', '/mypage/bookmark'),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(BuildContext ctx, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => Navigator.pushNamed(ctx, route),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Text(
              auth.isLoggedIn
                  ? '${auth.userEmail}님'
                  : '로그인이 필요합니다',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),

          // 마이페이지
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title:
            const Text('마이페이지', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mypage');
            },
          ),
          const Divider(color: Colors.white24),

          // 구매/입찰목록
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.white),
            title: const Text('구매/입찰목록',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mypage/purchase-bid');
            },
          ),

          // 판매목록/현황
          ListTile(
            leading: const Icon(Icons.store, color: Colors.white),
            title: const Text('판매목록/현황',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mypage/sale');
            },
          ),

          // 북마크
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.white),
            title:
            const Text('북마크', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mypage/bookmark');
            },
          ),

          if (auth.isLoggedIn) ...[
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('로그아웃',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ],
      ),
    );
  }
}
