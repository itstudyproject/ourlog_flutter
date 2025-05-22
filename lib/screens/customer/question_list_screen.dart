import 'package:flutter/material.dart';

class Inquiry {
  final String questionId;
  final String title;
  final String regDate;
  final bool answered;
  final String content;
  final String? answer;

  Inquiry({
    required this.questionId,
    required this.title,
    required this.regDate,
    required this.answered,
    required this.content,
    this.answer,
  });
}

class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final List<Inquiry> inquiries = [
    Inquiry(
      questionId: '1',
      title: '작품 등록 오류',
      regDate: '2025-05-20',
      answered: true,
      content: '작품 등록 시 오류가 발생합니다. 어떻게 해야 하나요?',
      answer: '작품 등록 오류는 서버 점검 중일 수 있습니다. 잠시 후 다시 시도해 주세요.',
    ),
    Inquiry(
      questionId: '2',
      title: '결제 관련 문의',
      regDate: '2025-05-18',
      answered: false,
      content: '결제 진행 중 결제 창이 닫히는데 문제인가요?',
      answer: null,
    ),
  ];

  void _handleEdit(Inquiry inquiry) {
    print('수정: ${inquiry.title}');
  }

  void _handleDelete(String id) {
    print('삭제: $id');
  }

  void _showRestrictedDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('알림'),
        content: Text('이미 답변된 문의는 $action할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: inquiries.isEmpty
              ? const Center(
            child: Text(
              '문의 내역이 없습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          )
              : ListView.builder(
            itemCount: inquiries.length,
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              inquiry.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              '작성일: ${inquiry.regDate}',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: inquiry.answered ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          inquiry.answered ? '답변 완료' : '답변 대기',
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white54,
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${inquiry.content}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (inquiry.answered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text(
                          '답변\n${inquiry.answer ?? '답변이 없습니다.'}',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: inquiry.answered
                              ? () => _showRestrictedDialog(context, '수정')
                              : () => _handleEdit(inquiry),
                          child: const Text('수정'),
                        ),
                        TextButton(
                          onPressed: inquiry.answered
                              ? () => _showRestrictedDialog(context, '삭제')
                              : () => _handleDelete(inquiry.questionId),
                          child: const Text(
                            '삭제',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: QuestionListScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
