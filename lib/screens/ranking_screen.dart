import 'package:flutter/material.dart';
import 'package:ourlog/models/post.dart';
import 'package:ourlog/services/ranking_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  State<RankingPage> createState() => _RankingPageState();
}

enum RankingKey { views, followers, downloads }

const badgeColors = [
  Color(0xFFF8C147),
  Color(0xFFB0B0B0),
  Color(0xFFA67C52),
];

class _RankingPageState extends State<RankingPage> {
  RankingKey rankingType = RankingKey.views;
  List<Post> artworks = [];
  int visibleCount = 12;
  final ScrollController _scrollController = ScrollController();

  late RankingService rankingService;

  @override
  void initState() {
    super.initState();

    rankingService = RankingService(); // 헤더 없이 생성

    fetchRankings();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        setState(() {
          visibleCount = (visibleCount + 6).clamp(0, artworks.length);
        });
      }
    });
  }


  Future<void> fetchRankings() async {
    try {
      final typeStr = rankingType.name;
      final data = await rankingService.fetchRanking(typeStr);
      setState(() {
        artworks = data;
        visibleCount = 12;
      });
    } catch (e) {
      print('랭킹 데이터 요청 실패: $e');
      setState(() {
        artworks = [];
      });
    }
  }

  String formatNumber(int? num) {
    if (num == null) return "0";
    if (num >= 1000000) {
      final val = (num / 1000000);
      return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1) + "M";
    }
    if (num >= 1000) {
      final val = (num / 1000);
      return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1) + "K";
    }
    return num.toString();
  }

  // 이미지 URL 얻는 함수 (포트폴리오와 아티스트 랭킹에 따라 다름)
  String getImageUrl(Post item, bool isArtistRanking) {
    const baseUrl = "http://localhost:8080/ourlog/picture/display";
    if (isArtistRanking) {
      if (item.profileImage != null && item.profileImage!.isNotEmpty) {
        return "$baseUrl/${item.profileImage}";
      }
      if (item.resizedImagePath != null && item.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/${item.resizedImagePath}";
      } else if (item.thumbnailImagePath != null && item.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/${item.thumbnailImagePath}";
      } else if (item.originImagePath != null) {
        if (item.originImagePath is String && (item.originImagePath as String).isNotEmpty) {
          return "$baseUrl/${item.originImagePath}";
        } else if (item.originImagePath is List && (item.originImagePath as List).isNotEmpty) {
          return "$baseUrl/${(item.originImagePath as List).first}";
        }
      } else if (item.fileName != null && item.fileName!.isNotEmpty) {
        return "$baseUrl/${item.fileName}";
      } else if (item.pictureDTOList != null && item.pictureDTOList!.isNotEmpty) {
        final pic = item.pictureDTOList!.first;
        if (pic['resizedImagePath'] != null && (pic['resizedImagePath'] as String).isNotEmpty) {
          return "$baseUrl/${pic['resizedImagePath']}";
        } else if (pic['thumbnailImagePath'] != null && (pic['thumbnailImagePath'] as String).isNotEmpty) {
          return "$baseUrl/${pic['thumbnailImagePath']}";
        } else if (pic['originImagePath'] != null && (pic['originImagePath'] as String).isNotEmpty) {
          return "$baseUrl/${pic['originImagePath']}";
        }
      }
    } else {
      if (item.resizedImagePath != null && item.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/${item.resizedImagePath}";
      } else if (item.thumbnailImagePath != null && item.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/${item.thumbnailImagePath}";
      } else if (item.originImagePath != null) {
        if (item.originImagePath is String && (item.originImagePath as String).isNotEmpty) {
          return "$baseUrl/${item.originImagePath}";
        } else if (item.originImagePath is List && (item.originImagePath as List).isNotEmpty) {
          return "$baseUrl/${(item.originImagePath as List).first}";
        }
      } else if (item.fileName != null && item.fileName!.isNotEmpty) {
        return "$baseUrl/${item.fileName}";
      }
    }
    return "/default-image.jpg";
  }

  Widget buildRankingButton(RankingKey key, String label) {
    final isActive = rankingType == key;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            rankingType = key;
          });
          fetchRankings();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          foregroundColor: isActive ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podium = artworks.take(3).toList();
    final rest = artworks.skip(3).take(visibleCount - 3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ranking Page"),
      ),
      body: Column(
        children: [
          Image.asset('assets/images/topranking.png', height: 100, fit: BoxFit.cover),
          Row(
            children: [
              buildRankingButton(RankingKey.views, "조회수"),
              buildRankingButton(RankingKey.followers, "팔로우"),
              buildRankingButton(RankingKey.downloads, "다운로드"),
            ],
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              children: [
                // Podium Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(3, (idx) {
                    if (idx >= podium.length) return const SizedBox.shrink();
                    final post = podium[idx];
                    final badgeColor = badgeColors[idx];
                    return GestureDetector(
                      onTap: () {
                        final path = rankingType == RankingKey.followers
                            ? '/worker/${post.userId}'
                            : '/Art/${post.postId}';
                        Navigator.pushNamed(context, path);
                      },
                      child: Card(
                        color: idx == 0 ? Colors.amber[300] : idx == 1 ? Colors.grey[400] : Colors.brown[300],
                        child: SizedBox(
                          width: 110,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    getImageUrl(post, rankingType == RankingKey.followers),
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset('assets/default-image.jpg', width: 110, height: 110);
                                    },
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: CircleAvatar(
                                      backgroundColor: badgeColor,
                                      child: Text("${idx + 1}", style: TextStyle(color: idx == 2 ? Colors.white : Colors.black)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rankingType == RankingKey.followers ? post.nickname ?? "" : post.title ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                rankingType == RankingKey.views
                                    ? "👁️ ${formatNumber(post.views)}"
                                    : rankingType == RankingKey.followers
                                    ? "👥 ${formatNumber(post.followers)}"
                                    : "⬇️ ${formatNumber(post.downloads)}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Rest List
                ...rest.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final post = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      onTap: () {
                        final path = rankingType == RankingKey.followers
                            ? '/worker/${post.userId}'
                            : '/Art/${post.postId}';
                        Navigator.pushNamed(context, path);
                      },
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(getImageUrl(post, rankingType == RankingKey.followers)),
                        onBackgroundImageError: (_, __) {},
                      ),
                      title: Text(rankingType == RankingKey.followers ? post.nickname ?? "" : post.title ?? ""),
                      subtitle: Text(
                        rankingType == RankingKey.views
                            ? "조회수: ${formatNumber(post.views)}"
                            : rankingType == RankingKey.followers
                            ? "팔로워: ${formatNumber(post.followers)}"
                            : "다운로드: ${formatNumber(post.downloads)}",
                      ),
                      trailing: Text("#${idx + 4}"),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
