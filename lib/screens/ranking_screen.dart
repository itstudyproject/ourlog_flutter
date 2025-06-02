import 'package:flutter/material.dart';
import 'package:ourlog/models/post.dart';
import 'package:ourlog/providers/auth_provider.dart';
import 'package:ourlog/services/ranking_service.dart';
import 'package:provider/provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

enum RankingKey { views, followers, downloads }

const badgeColors = [Color(0xFFF8C147), Color(0xFFB0B0B0), Color(0xFFA67C52)];

class _RankingScreenState extends State<RankingScreen> {
  RankingKey rankingType = RankingKey.views;
  List<Post> artworks = [];
  int visibleCount = 12;
  final ScrollController _scrollController = ScrollController();

  late RankingService rankingService;

  @override
  void initState() {
    super.initState();

    rankingService = RankingService();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        visibleCount = 0;
      });
    }
  }

  String formatNumber(int? num) {
    if (num == null) return "0";
    if (num >= 1000000) {
      final val = (num / 1000000);
      return "${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M";
    }
    if (num >= 1000) {
      final val = (num / 1000);
      return "${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}K";
    }
    return num.toString();
  }

  // 이미지 URL 얻는 함수 (포트폴리오와 아티스트 랭킹에 따라 다름)
  String getImageUrl(Post item, bool isArtistRanking) {
    const baseUrl = "http://10.100.204.54:8080/ourlog/picture/display";
    if (isArtistRanking) {
      if (item.profileImage != null && item.profileImage!.isNotEmpty) {
        return "$baseUrl/${item.profileImage}";
      }
      if (item.resizedImagePath != null && item.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/${item.resizedImagePath}";
      } else if (item.thumbnailImagePath != null &&
          item.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/${item.thumbnailImagePath}";
      } else if (item.originImagePath != null) {
        if (item.originImagePath is String &&
            (item.originImagePath as String).isNotEmpty) {
          return "$baseUrl/${item.originImagePath}";
        } else if (item.originImagePath is List &&
            (item.originImagePath as List).isNotEmpty) {
          return "$baseUrl/${(item.originImagePath as List).first}";
        }
      } else if (item.fileName != null && item.fileName!.isNotEmpty) {
        return "$baseUrl/${item.fileName}";
      } else if (item.pictureDTOList != null &&
          item.pictureDTOList!.isNotEmpty) {
        final pic = item.pictureDTOList!.first;
        if (pic.resizedImagePath != null &&
            (pic.resizedImagePath as String).isNotEmpty) {
          return "$baseUrl/${pic.resizedImagePath}";
        } else if (pic.thumbnailImagePath != null &&
            (pic.thumbnailImagePath as String).isNotEmpty) {
          return "$baseUrl/${pic.thumbnailImagePath}";
        } else if (pic.originImagePath != null &&
            (pic.originImagePath as String).isNotEmpty) {
          return "$baseUrl/${pic.originImagePath}";
        }
      }
    } else {
      if (item.resizedImagePath != null && item.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/${item.resizedImagePath}";
      } else if (item.thumbnailImagePath != null &&
          item.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/${item.thumbnailImagePath}";
      } else if (item.originImagePath != null) {
        if (item.originImagePath is String &&
            (item.originImagePath as String).isNotEmpty) {
          return "$baseUrl/${item.originImagePath}";
        } else if (item.originImagePath is List &&
            (item.originImagePath as List).isNotEmpty) {
          return "$baseUrl/${(item.originImagePath as List).first}";
        }
      } else if (item.fileName != null && item.fileName!.isNotEmpty) {
        return "$baseUrl/${item.fileName}";
      }
    }
    return "$baseUrl/default-image.jpg"; // 기본 이미지 경로 수정
  }

  // ✅ 추가: 랭킹 버튼 위젯 생성 함수
  Widget buildRankingButton(RankingKey key, String label) {
    final isActive = rankingType == key;
    return SizedBox(
      width: 100, // 버튼 너비 제한
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            rankingType = key;
          });
          fetchRankings(); // 랭킹 데이터 다시 불러오기
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.orange : Colors.white70,
          foregroundColor: isActive ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10), // 버튼 높이 조절
          textStyle: const TextStyle(fontSize: 14), // 글자 크기 조절
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ✅ 수정: 카드 위젯을 생성하는 공통 함수
  Widget buildRankingCard(
      BuildContext context,
      Post post,
      int rank,
      bool isArtistRanking, {
        double cardWidth = 150,
      }) {
    final badgeColor =
    rank >= 1 && rank <= 3
        ? badgeColors[rank - 1]
        : Colors.transparent; // 4위 이하는 투명

    final path = isArtistRanking ? '/worker' : '/Art';
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).userId;

    return GestureDetector(
      onTap: () {
        if (isArtistRanking) {
          Navigator.pushNamed(
            context,
            path,
            arguments: {
              'userId': post.userId,
              'currentUserId': currentUserId, // 여기에 로그인된 사용자 ID를 전달
            },
          );
        } else {
          Navigator.pushNamed(
            context,
            path,
            arguments: post.postId.toString(),
          );
        }
      },
      child: Card(
        elevation: 4,
        // 그림자 효과
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // 모서리 둥글게
        clipBehavior: Clip.antiAlias,
        // 자식이 border를 넘는 것 방지
        child: SizedBox(
          width: cardWidth,
          height: 200, // 카드 전체 높이 고정 (예시값, 필요 시 조정)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 영역: 고정 높이 또는 Flexible로 설정
              SizedBox(
                height: 150,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        getImageUrl(post, isArtistRanking),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),

                    // 랭킹 뱃지 (기존 그대로 유지)
                    if (rank >= 1 && rank <= 3)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: badgeColor,
                          radius: 12,
                          child: Text(
                            "$rank",
                            style: TextStyle(
                              color: rank == 3 ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (rank > 3)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: badgeColor,
                          radius: 12,
                          child: Text(
                            "$rank",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // ✅ 새로 추가: 이미지 위에 정보 오버레이
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 닉네임 또는 타이틀 (왼쪽)
                            Expanded(
                              child: Text(
                                isArtistRanking
                                    ? (post.nickname ?? "")
                                    : (post.title ?? ""),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // 통계 정보 (오른쪽)
                            Text(
                              rankingType == RankingKey.views
                                  ? "👁️ ${formatNumber(post.views)}"
                                  : rankingType == RankingKey.followers
                                  ? "👥 ${formatNumber(post.followers)}"
                                  : "⬇️ ${formatNumber(post.downloads)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podium = artworks.take(3).toList();
    final rest = artworks.skip(3).take(visibleCount - 3).toList();
    final isArtistRanking = rankingType == RankingKey.followers;

    // 화면 너비에 따른 카드 너비 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidthFor1 = screenWidth * 0.8; // 1위 카드는 화면 너비의 80%
    final cardWidthFor2_3 =
        (screenWidth - 40 - 10) / 2; // 2, 3위 카드는 좌우 패딩 20씩, 사이 간격 10을 뺀 너비를 2등분
    final cardWidthForRest =
        (screenWidth - 16 - (8 * 2)) /
            3; // 4위 이하 카드는 좌우 패딩 8씩, 사이 간격 8*2를 뺀 너비를 3등분 (GridView crossAxisSpacing)

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ranking", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, // AppBar 색상 설정
        iconTheme: const IconThemeData(color: Colors.white), // 뒤로가기 버튼 색상
      ),
      body: Container(
        // 배경색 설정을 위해 Container로 감싸기
        color: Colors.black, // 배경색 검정
        child: SafeArea(
          // 상단 노치 디자인 영역 피하기
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/topranking.png',
                width: screenWidth * 0.8,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildRankingButton(RankingKey.views, "조회수"),
                  const SizedBox(width: 10),
                  buildRankingButton(RankingKey.followers, "팔로우"),
                  const SizedBox(width: 10),
                  buildRankingButton(RankingKey.downloads, "다운로드"),
                ],
              ),
              const SizedBox(height: 24), // 버튼과 콘텐츠 간 간격
              // ✅ 데이터 로딩 중 또는 데이터 없음 메시지 표시
              if (artworks.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      "데이터를 불러오는 중입니다...", // 기본 로딩 메시지
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else // 데이터가 있을 경우
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    // 스크롤 컨트롤러 연결 (전체 스크롤 및 visibleCount 로직 유지)
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      // 좌우 패딩 추가
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬
                        children: [
                          // ✅ 1위 항목 (있을 경우)
                          if (podium.isNotEmpty) // 1위 항목이 있을 경우
                            Center(
                              // 중앙 정렬
                              child: buildRankingCard(
                                context,
                                podium[0],
                                1,
                                isArtistRanking,
                                cardWidth: cardWidthFor1,
                              ), // 1위 카드
                            ),

                          // ✅ 2, 3위 항목 (있을 경우)
                          if (podium.length >= 2) // 2위 항목이 있을 경우 (3위도 함께 표시)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              // 1위 카드와의 간격
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                // 중앙 정렬
                                children: [
                                  // 2위 카드
                                  buildRankingCard(
                                    context,
                                    podium[1],
                                    2,
                                    isArtistRanking,
                                    cardWidth: cardWidthFor2_3,
                                  ),
                                  const SizedBox(width: 10), // 2위와 3위 카드 사이 간격
                                  // 3위 카드 (있을 경우)
                                  if (podium.length >= 3) // 3위 항목이 있을 경우
                                    buildRankingCard(
                                      context,
                                      podium[2],
                                      3,
                                      isArtistRanking,
                                      cardWidth: cardWidthFor2_3,
                                    ),
                                ],
                              ),
                            ),

                          // ✅ 4위 이하 항목 (있을 경우)
                          if (rest.isNotEmpty) // 4위 이하 항목이 있을 경우
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              // 2, 3위 카드 또는 1위 카드와의 간격
                              child: GridView.builder(
                                shrinkWrap: true,
                                // Column 안에서 GridView 사용 시 필요
                                physics: const NeverScrollableScrollPhysics(),
                                // SingleChildScrollView가 스크롤을 처리하도록 함
                                itemCount: rest.length,
                                // 4위 이하 항목 개수
                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, // 한 줄에 3개 항목
                                  crossAxisSpacing: 8.0, // 좌우 간격
                                  mainAxisSpacing: 8.0, // 상하 간격
                                  childAspectRatio:
                                  cardWidthForRest /
                                      (cardWidthForRest +
                                          50), // 카드 내용에 맞게 비율 조절 (대략적인 값)
                                ),
                                itemBuilder: (context, idx) {
                                  final post = rest[idx];
                                  final rank = idx + 4; // 4위부터 시작
                                  return buildRankingCard(
                                    context,
                                    post,
                                    rank,
                                    isArtistRanking,
                                    cardWidth: cardWidthForRest,
                                  ); // 4위 이하 카드
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
