import 'package:flutter/material.dart';
import 'package:ourlog/models/inquiry.dart';
import 'package:ourlog/services/customer/answer_service.dart';
import 'package:ourlog/services/customer/question_service.dart';

class AnswerScreen extends StatefulWidget {
  final Inquiry? inquiry;
  const AnswerScreen({super.key, this.inquiry});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final AnswerService _answerService = AnswerService();
  final QuestionService _questionService = QuestionService();

  List<Inquiry> inquiries = [];
  bool isLoading = true;
  String? errorMessage;

  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, bool> _isEditing = {};

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  @override
  void dispose() {
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInquiries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      inquiries = await _questionService.fetchAllInquiries();

      for (var inquiry in inquiries) {
        final needsAnswer = inquiry.answer == null || (inquiry.answer!.contents.trim().isEmpty ?? true);
        _isEditing[inquiry.questionId] = needsAnswer;
        _answerControllers[inquiry.questionId] =
            TextEditingController(text: inquiry.answer?.contents ?? "");
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildInquiryItem(Inquiry inquiry) {
    final isEditing =
        _isEditing[inquiry.questionId] ?? (inquiry.answer == null || (inquiry.answer!.contents.trim().isEmpty ?? true));
    final answerController = _answerControllers[inquiry.questionId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User ID: ${inquiry.user?.userId ?? '정보 없음'}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          Text('User e-mail: ${inquiry.user?.email ?? '정보 없음'}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          Text('제목: ${inquiry.title}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          Text('내용: ${inquiry.content}', style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),

          if (isEditing)
            TextField(
              controller: answerController,
              maxLines: null,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.orange,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange, width: 2), // 포커스 시 오렌지색 테두리
                ),
                hintText: '답변을 입력하세요',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            )
          else if (inquiry.answered && inquiry.answer != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '답변: ',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inquiry.answer!.contents,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    final existingAnswer = inquiry.answer;
                    final newContents = answerController.text;
                    bool success;

                    if (existingAnswer != null) {
                      // 수정
                      success = await _answerService.modifyAnswer(
                        existingAnswer.answerId.toString(),
                        newContents,
                      );
                    } else {
                      // 작성
                      final answer = await _answerService.createAnswer(
                        inquiry.questionId,
                        newContents,
                      );
                      success = answer != null;
                    }

                    if (success) {
                      await _loadInquiries(); // 새로고침
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('답변이 저장되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('답변 저장에 실패했습니다.')),
                      );
                    }
                  },
                  child: const Text('저장', style: TextStyle(color: Colors.white)),
                ),

              if (isEditing)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing[inquiry.questionId] = false;
                      answerController.text = inquiries
                          .firstWhere((item) => item.questionId == inquiry.questionId)
                          .answer
                          ?.contents ?? "";
                    });
                  },
                  child: const Text('취소', style: TextStyle(color: Colors.white54)),
                ),

              if (!isEditing)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing[inquiry.questionId] = true;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  label: Text(
                    '답변 ${inquiry.answered ? "수정" : "작성"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

              if (!isEditing && inquiry.answered)
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('답변을 삭제하시겠습니까?',   textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('취소', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('삭제', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirm == true) {
                      final answerId = inquiry.answer?.answerId.toString();
                      if (answerId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('삭제할 답변 ID가 없습니다.')),
                        );
                        return;
                      }

                      final success = await _answerService.deleteAnswer(answerId);
                      if (success) {
                        setState(() {
                          final index = inquiries.indexWhere((item) => item.questionId == inquiry.questionId);
                          if (index != -1) {
                            inquiries[index] = Inquiry(
                              questionId: inquiry.questionId,
                              title: inquiry.title,
                              regDate: inquiry.regDate,
                              content: inquiry.content,
                              answered: false,
                              answer: null,
                              user: inquiry.user,
                            );
                          }
                          _isEditing[inquiry.questionId] = true;
                          _answerControllers[inquiry.questionId]?.text = "";
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('답변이 삭제되었습니다.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('답변 삭제에 실패했습니다.')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                  label: const Text('답변 삭제', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('전체 문의 목록 (관리자)', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text('오류 발생: $errorMessage', style: const TextStyle(color: Colors.redAccent)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inquiries.length,
        itemBuilder: (context, index) {
          final inquiry = inquiries[index];
          return _buildInquiryItem(inquiry);
        },
      ),
    );
  }
}
