import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'question': '비밀번호를 잊어버렸어요.', 'answer': '로그인 화면에서 "비밀번호 찾기"를 클릭해 주세요.'},
      {'question': '작품은 어떻게 등록하나요?', 'answer': '상단 메뉴에서 "아트 등록"을 선택하세요.'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: faqs.map((faq) {
        return ExpansionTile(
          title: Text(faq['question']!, style: const TextStyle(color: Colors.white)),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(faq['answer']!, style: const TextStyle(color: Colors.white70)),
            )
          ],
        );
      }).toList(),
    );
  }
}