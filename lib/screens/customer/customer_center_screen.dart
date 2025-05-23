import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'inquiry_screen.dart';
import 'question_list_screen.dart';

class CustomerCenterScreen extends StatefulWidget {
  final int initialTabIndex; // ← 추가

  const CustomerCenterScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends State<CustomerCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex, // ← 여기 반영
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 앱바 대체: 상단 고정 헤더
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
                  const Text('고객센터', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),

            // ✅ 항상 보이는 탭바
            Container(
              color: Colors.black,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.deepOrangeAccent[100],
                labelColor: Colors.deepOrangeAccent[100],
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),       // 선택된 탭 글자 스타일
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal), // 선택 안된 탭 글자 스타일
                isScrollable: false,
                tabs: const [
                  Tab(text: '자주 묻는 질문'),
                  Tab(text: '1:1 문의 하기'),
                  Tab(text: '1:1 문의 내역'),
                ],
              ),
            ),

            // ✅ 탭 컨텐츠는 스크롤 가능
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FaqScreen(),
                  InquiryScreen(),
                  QuestionListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}