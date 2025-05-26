import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';

class PostRegisterScreen extends StatefulWidget {
  const PostRegisterScreen({super.key});

  @override
  State<PostRegisterScreen> createState() => _PostRegisterScreenState();
}

class _PostRegisterScreenState extends State<PostRegisterScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  List<PictureDTO> images = [];
  String? selectedThumbnail;
  List<String> tags = [];
  String selectedCategory = '자유게시판';
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    loadDraft();
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

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _titleController.text = prefs.getString("draftTitle") ?? "";
    _contentController.text = prefs.getString("draftContent") ?? "";
  }

  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("draftTitle", _titleController.text);
    await prefs.setString("draftContent", _contentController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("임시저장 완료")));
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
        selectedThumbnail ??= pic.picName;
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

  void submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    final user = await getUser();

    final postDTO = {
      "title": _titleController.text,
      "content": _contentController.text,
      "boardNo": getBoardNo(selectedCategory),
      "fileName": selectedThumbnail,
      "pictureDTOList": images.map((img) => img.toJson()).toList(),
      "userDTO": {
        "userId": user['userId'],
        "nickname": user['nickname'],
      },
      "tag": tags.join(','),
    };

    final res = await http.post(
      Uri.parse('http://10.100.204.157:8080/ourlog/post/register'),
      headers: {
        "Content-Type": "application/json",
        ...(await getAuthHeaders()),
      },
      body: jsonEncode(postDTO),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시물이 등록되었습니다')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록 실패')),
      );
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('게시글 작성'),
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
                hintText: '내용을 입력하세요',
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
                      onTap: () => setState(() => selectedThumbnail = img.picName),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedThumbnail == img.picName ? Colors.blue : Colors.transparent,
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
                          if (selectedThumbnail == img.picName) {
                            selectedThumbnail = images.isNotEmpty ? images.first.picName : null;
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
                  onPressed: isSubmitting ? null : submitPost,
                  child: const Text('등록하기'),
                ),
                ElevatedButton(
                  onPressed: saveDraft,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                  child: const Text('임시저장'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
