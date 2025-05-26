import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'inquiry_screen.dart';
import 'questionlist_screen.dart';

class CustomerCenterScreen extends StatefulWidget {
  const CustomerCenterScreen({super.key});

  @override
  State<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends State<CustomerCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('고객센터', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelPadding: EdgeInsets.symmetric(horizontal: 12), // 탭 간 좌우 여백 줄이기
          tabs: const [
            Tab(text: '자주 묻는 질문'),
            Tab(text: '1:1 문의 하기'),
            Tab(text: '1:1 문의 내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FaqScreen(),
          InquiryScreen(),
          QuestionlistScreen(),
        ],
      ),
    );
  }
}