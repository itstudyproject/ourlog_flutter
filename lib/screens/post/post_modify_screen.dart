import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/post.dart';
import '../../services/auth_service.dart';


class PostModifyScreen extends StatefulWidget {
  final int postId;
  const PostModifyScreen({super.key, required this.postId});

  @override
  State<PostModifyScreen> createState() => _PostModifyScreenState();
}

class _PostModifyScreenState extends State<PostModifyScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  String selectedCategory = '자유게시판';
  String? thumbnail;
  List<PictureDTO> images = [];
  List<String> tags = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchPostData();
  }

  int getBoardNo(String category) {
    switch (category) {
      case '새소식':
        return 1;
      case '자유게시판':
        return 2;
      case '홍보게시판':
        return 3;
      case '요청게시판':
        return 4;
      default:
        return 2;
    }
  }

  String getCategoryFromNo(int boardNo) {
    switch (boardNo) {
      case 1:
        return '새소식';
      case 2:
        return '자유게시판';
      case 3:
        return '홍보게시판';
      case 4:
        return '요청게시판';
      default:
        return '자유게시판';
    }
  }

  Future<void> fetchPostData() async {
    final res = await http.get(Uri.parse('http://10.100.204.157:8080/ourlog/post/read/${widget.postId}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final post = Post.fromJson(data['postDTO']);
      setState(() {
        _titleController.text = post.title;
        _contentController.text = post.content;
        selectedCategory = getCategoryFromNo(post.boardNo ?? 2);
        thumbnail = post.fileName;
        images = post.pictureDTOList ?? [];
        tags = post.tag?.split(',') ?? [];
      });
    }
  }

  Future<void> uploadImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;

    for (final file in result.files) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.100.204.157:8080/ourlog/picture/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('files', file.path!));
      final res = await request.send();
      final body = await res.stream.bytesToString();
      final data = jsonDecode(body)[0];

      final pic = PictureDTO(
        uuid: data['uuid'],
        picName: data['picName'],
        path: data['path'],
        picId: data['picId'],
      );

      setState(() {
        images.add(pic);
        thumbnail ??= pic.picName;
      });
    }
  }

  void addTag(String tag) {
    if (tag.trim().isEmpty || tags.contains(tag.trim())) return;
    setState(() {
      tags.add(tag.trim());
      _tagController.clear();
    });
  }

  void removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  void submitEdit() async {
    setState(() => isSubmitting = true);
    final user = await getUser();

    final postDTO = {
      "postId": widget.postId,
      "title": _titleController.text,
      "content": _contentController.text,
      "boardNo": getBoardNo(selectedCategory),
      "fileName": thumbnail,
      "pictureDTOList": images.map((img) => img.toJson()).toList(),
      "tag": tags.join(','),
      "userId": user['userId']
    };

    final res = await http.put(
      Uri.parse('http://10.100.204.157:8080/ourlog/post/modify'),
      headers: {
        'Content-Type': 'application/json',
        ...(await getAuthHeaders()),
      },
      body: jsonEncode(postDTO),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("수정 완료")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("수정 실패")),
      );
    }

    setState(() => isSubmitting = false);
  }

  void deletePost() async {
    final res = await http.delete(
      Uri.parse('http://10.100.204.157:8080/ourlog/post/remove/${widget.postId}'),
      headers: await getAuthHeaders(),
    );
    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("삭제 완료")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("삭제 실패")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('게시글 수정'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ['자유게시판', '요청게시판', '홍보게시판']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
              dropdownColor: const Color(0xFF1f2937),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '카테고리'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '제목'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 10,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '내용 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: uploadImages, child: const Text('이미지 업로드')),
            Wrap(
              spacing: 8,
              children: images.map((img) {
                final url =
                    'http://10.100.204.157:8080/ourlog/picture/display/${img.path}/${img.uuid}_${img.picName}';
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    InkWell(
                      onTap: () => setState(() => thumbnail = img.picName),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: thumbnail == img.picName ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          images.remove(img);
                          if (thumbnail == img.picName) {
                            thumbnail = images.isNotEmpty ? images.first.picName : null;
                          }
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    )
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    onSubmitted: addTag,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '태그 입력'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => addTag(_tagController.text),
                  child: const Text('추가'),
                )
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () => removeTag(t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitEdit,
                  child: const Text('수정 완료'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: deletePost,
                  child: const Text('삭제하기'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
