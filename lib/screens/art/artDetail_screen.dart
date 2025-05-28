import 'package:flutter/material.dart';

class ArtDetailScreen extends StatelessWidget {
  final int postId;

  const ArtDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아트 상세 정보'), // 임시 제목
      ),
      body: Center(
        child: Text('게시글 ID: $postId 의 상세 정보를 표시할 화면입니다.'), // postId 확인용 텍스트
      ),
    );
  }
}
