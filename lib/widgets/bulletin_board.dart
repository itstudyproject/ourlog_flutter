import 'package:flutter/material.dart';

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

class BulletinBoard extends StatelessWidget {
  const BulletinBoard({super.key});

  Map<String, List<PostItem>> get mockData => {
    'news': [
      PostItem(
          id: 1,
          title: '새소식 게시물 1',
          description: '설명입니다.',
          date: '2023-05-21',
          category: 'news',
          thumbnail: null),
      PostItem(
          id: 2,
          title: '새소식 게시물 2',
          description: '다른 설명입니다.',
          date: '2023-05-22',
          category: 'news',
          thumbnail: null),
    ],
    'free': [],
    'promotion': [],
    'request': [],
  };

  static const Map<String, String> categoryLabels = {
    'news': '새소식',
    'free': '자유',
    'promotion': '홍보',
    'request': '요청',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset(
            'assets/images/bulletinboard.png',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          ...mockData.entries.map((entry) {
            final category = entry.key;
            final posts = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // 카테고리 전체 페이지로 이동
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      categoryLabels[category]!,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (posts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('게시글이 없습니다.'),
                  )
                else
                  Column(
                    children: posts.take(2).map((post) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: InkWell(
                          onTap: () {
                            // 상세 페이지로 이동
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
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        post.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          post.date,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
