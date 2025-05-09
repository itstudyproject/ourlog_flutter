import 'package:flutter/material.dart';
import '../constants/theme.dart';

class Header extends StatefulWidget {
  const Header({Key? key}) : super(key: key);

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with SingleTickerProviderStateMixin {
  bool _isSidebarOpen = false;
  bool _isLoggedIn = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  OverlayEntry? _overlayEntry;

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
            child: Image.asset('assets/images/OurLog.png', height: 55,)
          ),
          
          // 오른쪽: 검색 및 사용자 메뉴
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
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
                                style: const TextStyle(color: Colors.white, fontSize: 14),
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
                    
                    // 사용자 메뉴
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 마이페이지 아이콘
                        if (_isLoggedIn)
                          GestureDetector(
                            onTap: () {
                              // 마이페이지로 이동
                            },
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        const SizedBox(width: 16),
                        
                        // 로그인/로그아웃 버튼
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLoggedIn = !_isLoggedIn;
                            });
                          },
                          child: Text(
                            _isLoggedIn ? 'LOGOUT' : 'LOGIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            ),
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
                              
                              // 랭킹 섹션
                              _buildSidebarSection('랭킹', []),
                              
                              // 마이페이지 섹션
                              _buildSidebarSection('마이페이지', []),
                              
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

  void _closeSidebar() {
    _animationController.reverse().then((_) {
      _removeOverlay();
      setState(() {
        _isSidebarOpen = false;
      });
    });
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSidebarSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
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