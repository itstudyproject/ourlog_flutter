import 'package:flutter/material.dart';
import 'package:ourlog/models/inquiry.dart';
import 'package:ourlog/services/customer/inquiry_service.dart';


class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {

  final InquiryService _inquiryService = InquiryService();

  List<Inquiry> inquiries = [];
  List<bool> expandedList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
    //expandedList = List.filled(inquiries.length, false);
  }
  Future<void> _loadInquiries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      inquiries = (await _inquiryService.fetchInquiries()).cast<Inquiry>();
      expandedList = List.filled(inquiries.length, false);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleEdit(Inquiry inquiry) async {
    final titleController = TextEditingController(text: inquiry.title);
    final contentController = TextEditingController(text: inquiry.content);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '문의 수정하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.orange,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('제목', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('내용', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: const Text('취소', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: const Text('수정', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 서버에 수정 요청 보내기
      final success = await _inquiryService.editInquiry(
        inquiry.questionId,
        titleController.text,
        contentController.text,
      );

      if (success) {
        setState(() {
          // inquiries 리스트에서 해당 문의 찾아서 업데이트
          final index = inquiries.indexWhere((item) => item.questionId == inquiry.questionId);
          if (index != -1) {
            inquiries[index] = Inquiry(
              questionId: inquiry.questionId,
              title: titleController.text,
              regDate: inquiry.regDate,
              answered: inquiry.answered,
              content: contentController.text,
              answer: inquiry.answer,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  void _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 서버에 삭제 요청 보내기
      final success = await _inquiryService.deleteInquiry(id);

      if (success) {
        setState(() {
          inquiries.removeWhere((inquiry) => inquiry.questionId == id);
          expandedList = List.filled(inquiries.length, false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1:1 문의내역',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: inquiries.isEmpty
                    ? const Center(
                  child: Text('문의 내역이 없습니다.', style: TextStyle(color: Colors.white70)),
                )
                    : ListView.builder(
                  itemCount: inquiries.length,
                  itemBuilder: (context, index) {
                    final inquiry = inquiries[index];
                    final isExpanded = expandedList[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white54, width: 1.2),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() {
                            expandedList[index] = !expandedList[index];
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(inquiry.title,
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 16)),
                                        Text('작성일: ${inquiry.regDate}',
                                            style: const TextStyle(
                                                color: Colors.white54, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: inquiry.answered
                                          ? Colors.deepOrangeAccent
                                          : Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      inquiry.answered ? '답변 완료' : '답변 대기',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              AnimatedCrossFade(
                                firstChild: Container(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inquiry.content,
                                          style: const TextStyle(color: Colors.white)),
                                      if (inquiry.answered)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white12,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.black54),
                                          ),
                                          child: Text(
                                            '답변\n${inquiry.answer ?? '답변이 없습니다.'}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      if (!inquiry.answered)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue[400],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: TextButton(
                                                onPressed: () => _handleEdit(inquiry),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text('수정',
                                                    style: TextStyle(fontSize: 12)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: TextButton(
                                                onPressed: () => _handleDelete(inquiry.questionId),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text('삭제',
                                                    style: TextStyle(fontSize: 12)),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
