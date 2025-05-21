import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InquiryScreen extends StatelessWidget {
  const InquiryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inputStyle = InputDecoration(
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white30),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black, // 배경 색상 지정 (필요시)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('문의 제목', style: TextStyle(color: Colors.white)),
            TextField(decoration: inputStyle),

            const SizedBox(height: 24),
            const Text('문의 내용', style: TextStyle(color: Colors.white)),
            TextField(decoration: inputStyle, maxLines: 5),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 문의 전송 처리
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('문의가 접수되었습니다.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('문의하기'),
            ),
          ],
        ),
      ),
    );
  }
}
