import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? post;
  bool isLoading = true;
  String commentContent = '';
  final TextEditingController commentController = TextEditingController();

  Map<int, bool> isEditingMap = {};
  Map<int, TextEditingController> editControllers = {};

  int? currentUserId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchPost();
  }

  Future<void> getCurrentUser() async {
    final user = await getUser();
    setState(() {
      currentUserId = user['userId'];
    });
  }

  Future<void> fetchPost() async {
    setState(() => isLoading = true);
    final data = await PostService.fetchPost(widget.postId);
    setState(() {
      post = data;
      isLoading = false;
    });
  }

  Future<void> submitComment() async {
    if (commentContent.trim().isEmpty) return;
    final success = await PostService.submitComment(
      postId: widget.postId,
      content: commentContent,
    );
    if (success) {
      commentController.clear();
      commentContent = '';
      fetchPost();
    }
  }

  void toggleEdit(int replyId, String content) {
    setState(() {
      isEditingMap[replyId] = !(isEditingMap[replyId] ?? false);
      editControllers[replyId] = TextEditingController(text: content);
    });
  }

  Widget buildImages() {
    if (post?.pictureDTOList == null || post!.pictureDTOList!.isEmpty) return const SizedBox.shrink();
    return Column(
      children: post!.pictureDTOList!.map((pic) {
        final url =
            'http://10.100.204.157:8080/ourlog/picture/display/${pic.path}/${pic.uuid}_${pic.picName}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.network(url),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('게시글 상세', style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
              ? const Center(child: Text("게시글 없음", style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post!.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('작성자: ${post!.nickname}',
                          style: const TextStyle(color: Colors.grey)),
                      Text('작성일: ${post!.regDate?.substring(0, 10)}',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (post!.fileName != null)
                        Center(
                          child: Image.network(
                            'http://10.100.204.157:8080/ourlog/picture/display/${post!.path}/s_${post!.uuid}_${post!.fileName}',
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      buildImages(),
                      const SizedBox(height: 24),
                      Text(post!.content,
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                      const Divider(height: 40),
                      Text("댓글 (${post!.replyDTOList?.length ?? 0})",
                          style: const TextStyle(fontSize: 18, color: Colors.amber)),
                      const SizedBox(height: 12),
                      if (post!.replyDTOList != null)
                        Column(
                          children: post!.replyDTOList!.map((comment) {
                            final isOwner = comment.userDTO['userId'] == currentUserId;
                            final isEditing = isEditingMap[comment.replyId] ?? false;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2a2a2a),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.userDTO['nickname'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlueAccent)),
                                  const SizedBox(height: 4),
                                  isEditing
                                      ? TextField(
                                          controller: editControllers[comment.replyId],
                                          maxLines: 3,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: '댓글 수정 중...',
                                          ),
                                        )
                                      : Text(comment.content,
                                          style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(comment.regDate.substring(0, 16),
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12)),
                                      const Spacer(),
                                      if (isOwner)
                                        isEditing
                                            ? Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: () async {
                                                      final updated =
                                                          await PostService.updateComment(
                                                        comment.replyId,
                                                        editControllers[comment.replyId]!.text,
                                                      );
                                                      if (updated) fetchPost();
                                                    },
                                                    child: const Text("저장"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      toggleEdit(comment.replyId, comment.content);
                                                    },
                                                    child: const Text("취소"),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      toggleEdit(comment.replyId, comment.content);
                                                    },
                                                    child: const Text("수정"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      final confirm = await showDialog(
                                                        context: context,
                                                        builder: (_) => AlertDialog(
                                                          title: const Text("삭제 확인"),
                                                          content: const Text("댓글을 삭제하시겠습니까?"),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(context, false),
                                                                child: const Text("취소")),
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(context, true),
                                                                child: const Text("삭제")),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        final deleted =
                                                            await PostService.deleteComment(
                                                                comment.replyId);
                                                        if (deleted) fetchPost();
                                                      }
                                                    },
                                                    child: const Text("삭제",
                                                        style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '댓글을 입력하세요',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF2a2a2a),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Colors.grey)),
                        ),
                        onChanged: (val) => commentContent = val,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: submitComment,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("댓글 등록"),
                      )
                    ],
                  ),
                ),
    );
  }
}
