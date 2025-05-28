import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with SingleTickerProviderStateMixin {
  bool _isSidebarOpen = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  OverlayEntry? _overlayEntry;

  // 예시용 userId, currentUserId, 실제로는 authProvider 등에서 받아오세요
  final String userId = 'user123';
  final String currentUserId = 'currentUser456';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      height: 130,
      color: Colors.black.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 햄버거 메뉴
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              _showSidebar();
            },
          ),

          // 중앙: 로고
          GestureDetector(
              onTap: () {
                // 홈으로 이동
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Image.asset(
                'assets/images/OurLog.png',
                height: 55,
              )),

          // 오른쪽: 검색 및 사용자 메뉴
          Flexible(
            child: LayoutBuilder(builder: (context, constraints) {
              // 화면이 좁으면 검색창 숨기기
              final bool showSearch = constraints.maxWidth > 300;

              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showSearch) ...[
                    // 검색 레이블
                    const Text(
                      'SEARCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 검색창
                    Container(
                      width: 160,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style:
                              const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: '검색',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],

                  // MyPage 아이콘: 로그인 시에만 표시
                  if (authProvider.isLoggedIn) ...[
                    IconButton(
                      icon: Image.asset('assets/images/mypage.png'),
                      onPressed: () => Navigator.pushNamed(context, '/mypage'),
                    ),
                  ] else ...[
                    IconButton(
                      icon:
                      Image.asset('assets/images/mypage.png', color: Colors.white24),
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    ),
                  ],

                  // 로그인/로그아웃 버튼
                  GestureDetector(
                    onTap: () {
                      if (authProvider.isLoggedIn) {
                        authProvider.logout().then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그아웃 되었습니다')),
                          );
                        });
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: Text(
                      authProvider.isLoggedIn ? 'LOGOUT' : 'LOGIN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showSidebar() {
    _removeOverlay(); // 기존 오버레이 제거

    setState(() {
      _isSidebarOpen = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 오버레이 배경 (탭하면 닫힘)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSidebar,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),

              // 사이드바 내용
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    width: 300,
                    height: MediaQuery.of(context).size.height,
                    child: Material(
                      color: Colors.black,
                      child: SingleChildScrollView(
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 사이드바 헤더
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                      size: 30,
                                    ),
                                    onPressed: _closeSidebar,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),

                              // 로그인 상태에 따른 사용자 정보 표시
                              if (authProvider.isLoggedIn) ...[
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 30,
                                      child:
                                      Icon(Icons.person, size: 40, color: Colors.white),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authProvider.userEmail ?? '사용자',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () {
                                            _closeSidebar();
                                            Navigator.pushNamed(context, '/mypage');
                                          },
                                          child: const Text(
                                            '마이페이지',
                                            style: TextStyle(
                                              color: Color(0xFF9BCABF),
                                              fontSize: 14,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 16),
                              ],

                              // 아트 섹션
                              _buildSidebarSection('아트', [
                                '아트 등록',
                                '아트 게시판',
                              ]),

                              // 커뮤니티 섹션
                              _buildSidebarSection('커뮤니티', [
                                '새소식',
                                '자유게시판',
                                '홍보 게시판',
                                '요청 게시판',
                              ]),

                              // 랭킹 섹션 (클릭 시 /ranking 으로 이동하도록 처리)
                              _buildSidebarSection('랭킹', []),

                              // 마이페이지 섹션 (로그인 시에만 표시)
                              if (authProvider.isLoggedIn)
                                _buildSidebarSection('마이페이지', [
                                  '프로필 관리',
                                  '나의 작품',
                                  '좋아요 목록',
                                  '구매 내역',
                                  '설정',
                                ]),

                              // 회원탈퇴 섹션 (로그인 시에만 표시)
                              if (authProvider.isLoggedIn)
                                GestureDetector(
                                  onTap: () {
                                    _closeSidebar();
                                    Navigator.pushNamed(context, '/delete');
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '회원탈퇴',
                                              style: TextStyle(
                                                color: Colors.red[300],
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // 여기에 Divider와 '작가 페이지' 메뉴 추가
                              const Divider(color: Colors.white54),
                              GestureDetector(
                                onTap: () async {
                                  await _closeSidebar();
                                  Navigator.pushNamed(context, '/worker', arguments: {
                                    'userId': userId,
                                    'currentUserId': currentUserId,
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Text(
                                    '작가 페이지',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),

                              // 하단 로고
                              Padding(
                                padding: const EdgeInsets.only(top: 40, bottom: 70),
                                child: Opacity(
                                  opacity: 0.7,
                                  child: Text(
                                    'OurLog',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  Future<void> _closeSidebar() async {
    await _animationController.reverse();
    _removeOverlay();
    setState(() => _isSidebarOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSidebarSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _closeSidebar();
            if (title == '랭킹') {
              Navigator.pushNamed(context, '/ranking');
            }
            // 필요한 다른 섹션도 여기서 처리 가능
          },
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => _buildSidebarItem(item)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSidebarItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTap: () {
          // 해당 메뉴로 이동
          _closeSidebar();

          // 메뉴 항목에 따른 라우팅 처리
          switch (title) {
            case '프로필 관리':
              Navigator.pushNamed(context, '/mypage/profile');
              break;
            case '나의 작품':
              Navigator.pushNamed(context, '/mypage/works');
              break;
            case '좋아요 목록':
              Navigator.pushNamed(context, '/mypage/likes');
              break;
            case '구매 내역':
              Navigator.pushNamed(context, '/mypage/purchases');
              break;
            case '설정':
              Navigator.pushNamed(context, '/mypage/settings');
              break;
            case '아트 등록':
              Navigator.pushNamed(context, '/art/register');
              break;
            case '아트 게시판':
              Navigator.pushNamed(context, '/art/board');
              break;
            case '새소식':
              Navigator.pushNamed(context, '/community/news');
              break;
            case '자유게시판':
              Navigator.pushNamed(context, '/community/free');
              break;
            case '홍보 게시판':
              Navigator.pushNamed(context, '/community/promo');
              break;
            case '요청 게시판':
              Navigator.pushNamed(context, '/community/request');
              break;
            default:
              break;
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
