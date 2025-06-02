import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/main_layout.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ProfileService _service = ProfileService();
  int? _userId;
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId;
    _load();
  }

  Future<void> _load() async {
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = await _service.fetchProfile(_userId!);
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // 에러 처리
    } finally {
      if (mounted) {
        debugPrint('★★★ fetchProfile 성공, 이미지 URL 확인: thumbnailImagePath=${_profile?.thumbnailImagePath}, profileImageUrl=${_profile?.profileImageUrl}');
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }
    return MainLayout(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            SizedBox(height: 30),
            _SectionTitle('메뉴'),
            SizedBox(height: 10),
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
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF333333),
            backgroundImage: NetworkImage(
              'http://10.100.204.124:8080' + (_profile?.thumbnailImagePath ?? ''),
              headers: {
                'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
              },
            ) as ImageProvider,

          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.nickname,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '팔로워: ${_profile!.followCnt}   팔로잉: ${_profile!.followingCnt}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF333333),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          if (_userId == null) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }
                          final result = await Navigator.pushNamed(
                            context,
                            '/mypage/edit',
                            arguments: _userId!,
                          ) as bool?;
                          if (result == true) {
                            _load();
                          }
                        },
                        child: Text(
                          '프로필수정',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    _actionButton('회원정보수정', '/mypage/account/edit'),
                    SizedBox(width: 8),
                    _actionButton(
                      '회원탈퇴',
                      '/mypage/account/delete',
                      backgroundColor: Colors.red,
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

  Widget _actionButton(String label, String route,
      {Color backgroundColor = const Color(0xFF333333)}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () {
          if (_userId == null) {
            Navigator.pushNamed(context, '/login');
            return;
          }
          Navigator.pushNamed(
            context,
            route,
            arguments: _userId!,
          );
        },
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _menuButton(String label, String route) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Color(0xFF232323),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Color(0xFF333333)),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () {
          if (_userId == null) {
            Navigator.pushNamed(context, '/login');
            return;
          }
          Navigator.pushNamed(
            context,
            route,
            arguments: _userId!,
          );
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
