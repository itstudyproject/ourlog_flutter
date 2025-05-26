// lib/screens/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/header.dart';


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

    try {
      final profile = await _service.fetchProfile(userId);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      // error handling 생략
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 프로필 없음
    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    // Use the same header+footer as HomeScreen via MainLayout :contentReference[oaicite:1]{index=1}
        return MainLayout(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 30),
                const _SectionTitle('메뉴'),
                const SizedBox(height: 10),
               _menuButton('구매/입찰목록', '/mypage/purchase-bid'),
                _menuButton('판매목록/현황', '/mypage/sale'),
                _menuButton('북마크', '/mypage/bookmark'),
              ],
            ),
          ),
        );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF333333),
            backgroundImage: NetworkImage(_profile!.thumbnailImagePath),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '팔로워: ${_profile!.followCnt}   팔로잉: ${_profile!.followingCnt}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _actionButton('프로필수정', '/mypage/edit'),
                    const SizedBox(width: 8),
                    _actionButton('회원정보수정', '/mypage/account/edit'),
                    const SizedBox(width: 8),
                    _actionButton('회원탈퇴', '/mypage/account/delete',
                        backgroundColor: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, String route,
      {Color backgroundColor = const Color(0xFF333333)}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _menuButton(String label, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF232323),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF333333)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () => Navigator.pushNamed(context, route),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF232323)),
            child: Text(
              auth.isLoggedIn ? '${auth.userEmail}님' : '로그인이 필요합니다',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          _drawerItem(Icons.person, '마이페이지', '/mypage'),
          const Divider(color: Color(0xFF333333)),
          _drawerItem(Icons.shopping_cart, '구매/입찰목록', '/mypage/purchase-bid'),
          _drawerItem(Icons.store, '판매목록/현황', '/mypage/sale'),
          _drawerItem(Icons.bookmark, '북마크', '/mypage/bookmark'),
          if (auth.isLoggedIn) ...[
            const Divider(color: Color(0xFF333333)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('로그아웃',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

/// 웹 CSS의 h2 스타일을 흉내낸 위젯
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
