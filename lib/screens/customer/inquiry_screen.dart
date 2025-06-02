import 'package:flutter/material.dart';
import 'package:ourlog/screens/customer/customer_center_screen.dart';
import 'package:ourlog/services/customer/question_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final QuestionService questionService = QuestionService();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(() => setState(() {}));
    _contentFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color getBorderColor(FocusNode focusNode) {
      return focusNode.hasFocus ? const Color(0xFFF8C147) : Colors.white30;
    }

    // AuthProvider 가져오기 (로그인 상태 확인용)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1:1 문의하기',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 2,
                width: double.infinity,
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              const Text(
                  '서비스 이용 중 불편하신 점이나 문의사항을 남겨주시면 신속하게 답변 드리도록 하겠습니다.',
                  style: TextStyle(color: Colors.white70)),
              const Text(
                  '영업일 기준(주말·공휴일 제외) 3일 이내에 답변드리겠습니다. 단, 문의가 집중되는 경우 답변이 지연될 수 있습니다.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '산업안전보건법에 따라 폭언, 욕설, 성희롱, 반말, 비하, 반복적인 요구 등에는 회신 없이 상담을 즉시 종료하며 이후 문의에도 회신하지 않습니다. 고객응대 근로자를 보호하기 위해 이같은 이용자의 서비스 이용을 제한하고, 업무방해, 모욕죄 등으로 민형사상 조치를 취할 수 있음을 알려드립니다.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),

              // 제목
              const Text('제목', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: getBorderColor(_titleFocusNode)),
                ),
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white54),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 내용
              const Text('내용', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: getBorderColor(_contentFocusNode)),
                ),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '내용을 입력하세요',
                    hintStyle: TextStyle(color: Colors.white54),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // 로그인 체크
                    if (authProvider.token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인이 필요합니다.')),
                      );
                      await Future.delayed(const Duration(seconds: 1));
                      Navigator.of(context).pushReplacementNamed('/login');
                      return;
                    }

                    final title = _titleController.text;
                    final content = _contentController.text;

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          content: const Text(
                            '제목을 입력해주세요.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                      return;
                    }

                    if (content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          content: const Text(
                            '내용을 입력해주세요.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                      return;
                    }

                    // 백엔드에 문의 내용 전송
                    bool success = await questionService.submitInquiry(title, content);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('문의가 접수되었습니다.')),
                      );
                      _titleController.clear();
                      _contentController.clear();

                      // 문의내역 화면으로 이동
                      await Future.delayed(const Duration(seconds: 1));
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => CustomerCenterScreen(
                            initialTabIndex: 2,
                            isAdmin: false, // 또는 true (로그인 사용자에 따라 달라질 수 있음)
                          ),                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('문의 접수에 실패했습니다.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('문의하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
