import 'package:flutter/material.dart';

class CommunityPostDetailScreen extends StatelessWidget {
  final int postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
      ),
      body: Center(
        child: Text('Post ID: $postId'),
      ),
    );
  }
} 