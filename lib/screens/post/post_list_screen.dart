import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/post.dart';

class PostListScreen extends StatefulWidget {
  final int boardNo; // 🔥 arguments로 전달된 게시판 번호

  const PostListScreen({super.key, this.boardNo = 2});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final List<String> categories = ['새소식', '자유게시판', '홍보게시판', '요청게시판'];
  final Map<String, int> boardIdMap = {
    '새소식': 1,
    '자유게시판': 2,
    '홍보게시판': 3,
    '요청게시판': 4,
  };

  late int selectedBoardId;
  int currentPage = 1;
  int totalPages = 1;
  final int postsPerPage = 10;

  List<Post> posts = [];
  bool isLoading = true;
  String searchKeyword = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBoardId = widget.boardNo; // ✅ 라우팅 전달값으로 초기화
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    final uri = Uri.parse(
        'http://10.100.204.157:8080/ourlog/post/list?page=$currentPage&size=$postsPerPage&boardNo=$selectedBoardId&type=all&keyword=$searchKeyword');

    final res = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List<Post> fetched = [];

      for (var item in data['pageResultDTO']['dtoList']) {
        final postId = item['postId'] ?? item['id'];
        final thumbnailPic = (item['pictureDTOList'] as List?)
            ?.firstWhere((pic) => pic['picName'] == item['fileName'], orElse: () => null);

        fetched.add(Post(
          postId: postId,
          title: item['title'],
          content: item['content'] ?? '',
          nickname: item['nickname'] ?? '익명',
          regDate: item['regDate'] ?? '',
          boardNo: item['boardNo'],
          fileName: thumbnailPic?['picName'],
          uuid: thumbnailPic?['uuid'],
          path: thumbnailPic?['path'],
        ));
      }

      setState(() {
        posts = fetched;
        totalPages = data['pageResultDTO']['totalPage'] ?? 1;
        isLoading = false;
      });
    } else {
      setState(() {
        posts = [];
        totalPages = 1;
        isLoading = false;
      });
    }
  }

  Widget buildTabMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((label) {
        final isActive = boardIdMap[label] == selectedBoardId;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedBoardId = boardIdMap[label]!;
              currentPage = 1;
              fetchPosts();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? Colors.grey[800] : Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.amber : Colors.grey[300],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '키워드로 검색해주세요',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2a2a2a),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF555555)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onSubmitted: (_) {
              searchKeyword = searchController.text;
              fetchPosts();
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            searchKeyword = searchController.text;
            fetchPosts();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
          ),
          child: const Text('검색'),
        )
      ],
    );
  }

  Widget buildPostList() {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text('게시글이 없습니다.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Column(
      children: posts.map((post) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          onTap: () {
            Navigator.pushNamed(context, '/post/detail', arguments: post.postId);
          },
          title: Text(
            post.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              Text('작성자: ${post.nickname ?? "익명"}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 10),
              Text('${post.regDate?.substring(0, 10)}',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          leading: post.fileName != null
              ? Image.network(
            'http://localhost:8080/ourlog/picture/display/${post.path}/s_${post.uuid}_${post.fileName}',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a2a),
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: const Text(
              '없음',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildPagination() {
    List<Widget> pageButtons = [];
    final start = ((currentPage - 1) ~/ 10) * 10 + 1;
    final end = (start + 9).clamp(1, totalPages);

    for (int i = start; i <= end; i++) {
      pageButtons.add(
        ElevatedButton(
          onPressed: () {
            setState(() {
              currentPage = i;
              fetchPosts();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == i ? Colors.amber : Colors.grey[800],
          ),
          child: Text('$i'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: pageButtons,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('게시글 목록', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTabMenu(),
            const SizedBox(height: 16),
            buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(child: buildPostList()),
            ),
            const SizedBox(height: 16),
            buildPagination(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/post/register');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
