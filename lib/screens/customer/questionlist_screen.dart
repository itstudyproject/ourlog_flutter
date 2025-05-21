import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuestionlistScreen extends StatelessWidget {
  const QuestionlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inquiries = [
      {'title': '작품 등록 오류', 'status': '답변 완료'},
      {'title': '결제 관련 문의', 'status': '처리 중'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: inquiries.length,
      separatorBuilder: (_, __) => const Divider(color: Color(0x40FFFFFF)), // white24
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        return ListTile(
          title: Text(inquiry['title']!, style: const TextStyle(color: Color(0xFFFFFFFF))),
          trailing: Text(inquiry['status']!, style: const TextStyle(color: Color(0xFF64FFDA))),
        );
      },
    );
  }
}
