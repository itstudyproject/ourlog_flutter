import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostItem {
  final int id;
  final String title;
  final String description;
  final String date;
  final String category;
  final String? thumbnail;

  PostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.thumbnail,
  });
}

class BulletinBoard extends StatefulWidget {
  const BulletinBoard({super.key});

  @override
  State<BulletinBoard> createState() => _BulletinBoardState();
}

class _BulletinBoardState extends State<BulletinBoard> {
  final Map<String, String> categoryLabels = {
    'news': '새소식',
    'free': '자유',
    'promotion': '홍보',
    'request': '요청',
  };

  final Map<String, int> boardIdMap = {
    'news': 1,
    'free': 2,
    'promotion': 3,
    'request': 4,
  };

  Map<String, List<PostItem>> categoryPosts = {
    'news': [],
    'free': [],
    'promotion': [],
    'request': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPostsByCategory();
  }

  Future<void> fetchPostsByCategory() async {
    final Map<int, PostItem> uniquePosts = {};

    for (final entry in boardIdMap.entries) {
      final category = entry.key;
      final boardNo = entry.value;
      final url =
          'http://10.100.204.171:8080/ourlog/post/list?boardNo=$boardNo&size=10&type=t&keyword=';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dtoList = data['pageResultDTO']['dtoList'] as List<dynamic>;

          final posts =
              dtoList.map((item) {
                final id = item['postId'] ?? item['id'];
                final date =
                    item['regDate']?.split("T")[0] ??
                    item['createdAt']?.split("T")[0] ??
                    "";

                // 썸네일 URL 생성
                String? thumbnail;
                final pictureList = item['pictureDTOList'] ?? [];
                final fileName = item['fileName'];
                final pic = pictureList.firstWhere(
                  (p) => p['picName'] == fileName,
                  orElse: () => null,
                );
                if (pic != null) {
                  thumbnail =
                      'http://10.100.204.171:8080/ourlog/picture/display/${pic['path']}/s_${pic['uuid']}_${pic['picName']}';
                }

                return PostItem(
                  id: id,
                  title: item['title'] ?? '',
                  description: item['content'] ?? '설명 없음',
                  date: date,
                  category: category,
                  thumbnail: thumbnail,
                );
              }).toList();

          final List<PostItem> filtered = [];
          for (final post in posts) {
            if (filtered.length >= 2) break;
            if (!uniquePosts.containsKey(post.id)) {
              uniquePosts[post.id] = post;
              filtered.add(post);
            }
          }

          setState(() {
            categoryPosts[category] = filtered;
          });
        }
      } catch (e) {
        print('Error fetching $category posts: $e');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset(
                'assets/images/bulletinboard.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              ...categoryPosts.entries.map((entry) {
                final category = entry.key;
                final posts = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        //커뮤니티 페이지 이동
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => CategoryPostsScreen(category: category),
                        //   ),
                        // );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          categoryLabels[category]!,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (posts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          '게시글이 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    else
                      Column(
                        children:
                            posts.map((post) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // 상세페이지 이동
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) => PostDetailScreen(postId: post.id),
                                    //   ),
                                    // );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        post.thumbnail != null
                                            ? Image.network(
                                              post.thumbnail!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                            ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                post.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                post.date,
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
  }
}
