import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'faq_screen.dart';
import 'inquiry_screen.dart';
import 'question_list_screen.dart';
import 'answer_screen.dart'; // 관리자 답변 화면 import

class CustomerCenterScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool isAdmin;

  const CustomerCenterScreen({
    super.key,
    this.initialTabIndex = 0,
    required this.isAdmin,
  });

  @override
  State<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends State<CustomerCenterScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentTabsLength = 0;
  bool _checkedAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAdminAndRedirect();
  }

  Future<void> _checkAdminAndRedirect() async {
    if (_checkedAdmin) return;
    _checkedAdmin = true;

    final admin = await AuthProvider.checkIsAdmin();
    if (admin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AnswerScreen()),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    final tabs = <Tab>[
      const Tab(text: '자주 묻는 질문'),
      if (isLoggedIn) const Tab(text: '1:1 문의 하기'),
      if (isLoggedIn) const Tab(text: '1:1 문의 내역'),
    ];

    final tabViews = <Widget>[
      const FaqScreen(),
      if (isLoggedIn) const InquiryScreen(),
      if (isLoggedIn) QuestionListScreen(),
    ];

    // TabController를 필요할 때만 초기화
    if (_tabController == null || _currentTabsLength != tabs.length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: tabs.length,
        vsync: this,
        initialIndex: (widget.initialTabIndex < tabs.length)
            ? widget.initialTabIndex
            : 0,
      );
      _currentTabsLength = tabs.length;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('고객센터',
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (isLoggedIn) {
                        authProvider.logout();
                        Navigator.of(context).pushReplacementNamed('/login');
                      } else {
                        Navigator.of(context).pushNamed('/login');
                      }
                    },
                    child: Text(
                      isLoggedIn ? 'LOGOUT' : 'LOGIN',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // 탭바 및 뷰
            Container(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.deepOrangeAccent[100],
                labelColor: Colors.deepOrangeAccent[100],
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal),
                tabs: tabs,
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: tabViews,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
