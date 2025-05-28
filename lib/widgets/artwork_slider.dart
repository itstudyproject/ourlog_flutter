import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Artwork 모델 정의
class Artwork {
  final String imageUrl;
  final String title;
  final String artist;
  final String highestBid;
  final String link;
  final bool isArtist;
  final int followers;

  Artwork({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.highestBid,
    required this.link,
    this.isArtist = false,
    this.followers = 0,
  });

  factory Artwork.fromJson(Map<String, dynamic> json, {bool isArtist = false}) {
    String getImageUrl(Map<String, dynamic> item) {
      if (item['pictureDTOList'] != null && item['pictureDTOList'].isNotEmpty) {
        final picData = item['pictureDTOList'][0];
        if (picData['resizedImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${picData['resizedImagePath']}";
        if (picData['thumbnailImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${picData['thumbnailImagePath']}";
        if (picData['originImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${picData['originImagePath']}";
        if (picData['fileName'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${picData['fileName']}";
      } else {
        if (item['resizedImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${item['resizedImagePath']}";
        if (item['thumbnailImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${item['thumbnailImagePath']}";
        if (item['originImagePath'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${item['originImagePath']}";
        if (item['fileName'] != null) return "http://10.100.204.54:8080/ourlog/picture/display/${item['fileName']}";
      }
      return "http://10.100.204.54:8080/ourlog/picture/display/default-image.jpg";
    }

    String highestBidFormatted = "";
    if (json['tradeDTO'] != null &&
        json['tradeDTO']['highestBid'] != null &&
        num.tryParse(json['tradeDTO']['highestBid'].toString()) != null &&
        num.parse(json['tradeDTO']['highestBid'].toString()) > 0) {
      highestBidFormatted = "₩${int.parse(json['tradeDTO']['highestBid'].toString()).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";
    }

    return Artwork(
      imageUrl: getImageUrl(json),
      title: json['title'] ?? (isArtist ? "대표작 없음" : ""),
      artist: json['nickname'] ?? "unknown",
      highestBid: highestBidFormatted,
      link: isArtist
          ? (json['userId'] != null ? "/worker/${json['userId']}" : "/worker/unknown")
          : "/Art/${json['postId']}",
      isArtist: isArtist,
      followers: isArtist && json['followers'] != null ? json['followers'] as int : 0,
    );
  }
}

class ArtworkSlider extends StatefulWidget {
  const ArtworkSlider({super.key});

  @override
  State<ArtworkSlider> createState() => _ArtworkSliderState();
}

class _ArtworkSliderState extends State<ArtworkSlider> {
  static const String viewsApiUrl = "http://10.100.204.54:8080/ourlog/ranking?type=views";
  static const String followersApiUrl = "http://10.100.204.54:8080/ourlog/ranking?type=followers";

  List<Artwork> artworks = [];
  List<Artwork> artists = [];

  // 무작위 항목 선택을 위한 변수 다시 추가
  List<int> artworkIndexes = [];
  List<int> artistIndexes = [];

  Timer? _timer;

  int hoveredIndex = -1;

  // 자동 스크롤을 위한 변수 유지
  final ScrollController _artworkScrollController = ScrollController();
  final ScrollController _artistScrollController = ScrollController();
  int _currentArtworkIndex = 0; // 스크롤 위치 추적을 위한 인덱스
  int _currentArtistIndex = 0; // 스크롤 위치 추적을 위한 인덱스
  static const int _displayCount = 3; // 한 번에 보여줄 항목 수

  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      // 데이터 로드 후 초기 무작위 인덱스 설정
      setState(() {
        artworkIndexes = getRandomIndexes(artworks.length, _displayCount);
        artistIndexes = getRandomIndexes(artists.length, _displayCount);
      });
    });

    // 타이머 동작: 스크롤 위치 이동과 무작위 인덱스 갱신
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return; // 위젯이 해제되면 타이머 중지

      // 인기 작품 슬라이드 및 인덱스 갱신
      if (artworks.length > 0) {
        // 다음 스크롤 위치 인덱스 계산 (무한 스크롤처럼 보이게 % 연산 사용)
        _currentArtworkIndex = (_currentArtworkIndex + 1);

        // 리스트의 끝에 도달하면 처음으로 순간 이동 후 다시 스크롤 시작 (자연스러운 반복을 위한 처리)
        if (_currentArtworkIndex >= artworks.length) {
          _artworkScrollController.jumpTo(0);
          _currentArtworkIndex = 0;
        }

        _artworkScrollController.animateTo(
          _currentArtworkIndex * (350 + 40), // 항목 너비(350) + 간격(40)
          duration: const Duration(milliseconds: 800), // 스크롤 애니메이션 시간
          curve: Curves.easeInOut, // 부드러운 애니메이션 커브
        );


        // 무작위 인덱스도 매 타이머마다 다시 생성
        setState(() {
          artworkIndexes = getRandomIndexes(artworks.length, _displayCount);
        });
      }

      // 주요 아티스트 슬라이드 및 인덱스 갱신
      if (artists.length > 0) {
        // 다음 스크롤 위치 인덱스 계산 (무한 스크롤처럼 보이게 % 연산 사용)
        _currentArtistIndex = (_currentArtistIndex + 1);

        // 리스트의 끝에 도달하면 처음으로 순간 이동 후 다시 스크롤 시작 (자연스러운 반복을 위한 처리)
        if (_currentArtistIndex >= artists.length) {
          _artistScrollController.jumpTo(0);
          _currentArtistIndex = 0;
        }

        _artistScrollController.animateTo(
          _currentArtistIndex * (350 + 40), // 항목 너비(350) + 간격(40)
          duration: const Duration(milliseconds: 800), // 스크롤 애니메이션 시간
          curve: Curves.easeInOut, // 부드러운 애니메이션 커브
        );


        // 무작위 인덱스도 매 타이머마다 다시 생성
        setState(() {
          artistIndexes = getRandomIndexes(artists.length, _displayCount);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _artworkScrollController.dispose(); // 스크롤 컨트롤러 해제
    _artistScrollController.dispose(); // 스크롤 컨트롤러 해제
    super.dispose();
  }

  // 무작위 인덱스 생성 함수 다시 추가
  List<int> getRandomIndexes(int length, int count) {
    if (length == 0) return [];
    final List<int> indexes = [];
    final maxCount = length < count ? length : count;
    final random = Random();

    while (indexes.length < maxCount) {
      final rand = random.nextInt(length);
      if (!indexes.contains(rand)) {
        indexes.add(rand);
      }
    }
    return indexes;
  }

  Future<void> fetchData() async {
    try {
      final resArtworks = await http.get(Uri.parse(viewsApiUrl));
      if (resArtworks.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtworks.body);
        final mapped = data.map((e) => Artwork.fromJson(e)).toList();
        setState(() {
          artworks = mapped;
          // 초기 무작위 인덱스는 fetchData().then()에서 설정
        });
      }
    } catch (e) {
      debugPrint("인기 작품 불러오기 실패: $e");
    }

    try {
      final resArtists = await http.get(Uri.parse(followersApiUrl));
      if (resArtists.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtists.body);
        final mapped = data.map((e) => Artwork.fromJson(e, isArtist: true)).toList();
        setState(() {
          artists = mapped;
          // 초기 무작위 인덱스는 fetchData().then()에서 설정
        });
      }
    } catch (e) {
      debugPrint("주요 아티스트 불러오기 실패: $e");
    }
  }

  // buildSection 함수의 인덱스 관련 부분 및 ListView 수정 (무작위 인덱스 사용)
  Widget buildSection(String title, String subtitle, List<Artwork> data, List<int> indexes, ScrollController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/ranking');
          },
          child: Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
        data.isEmpty || indexes.isEmpty // 데이터 또는 인덱스가 없으면 메시지 표시
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title == "인기 작품 추천" ? "인기 작품이 없습니다." : "주요 아티스트가 없습니다.",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : SizedBox(
          height: 400,
          child: ListView.separated(
            controller: controller, // 스크롤 컨트롤러 연결
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: indexes.length, // 무작위로 선택된 항목 수만큼 표시
            separatorBuilder: (context, _) => const SizedBox(width: 40),
            itemBuilder: (context, i) {
              int idx = indexes[i]; // 무작위 인덱스 사용
              if (idx >= data.length) return const SizedBox.shrink(); // 데이터 범위를 벗어나면 빈 위젯 반환
              final item = data[idx]; // 무작위 인덱스에 해당하는 데이터 항목 사용

              return GestureDetector(
                onTap: () {
                  showArtworkInfoDialog(context, item);
                },
                child: Container(
                  width: 350,
                  height: 350,
                  // 이미지 표시 방식은 showArtworkInfoDialog 함수에서 수정됨
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover, // ListView 썸네일 이미지는 cover 유지
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          // buildSection 호출 시 무작위 인덱스와 스크롤 컨트롤러 모두 전달
          buildSection(
            "인기 작품 추천",
            "사람들의 마음을 사로잡은 그림들을 소개합니다",
            artworks,
            artworkIndexes, // 무작위 인덱스 전달
            _artworkScrollController, // 스크롤 컨트롤러 전달
          ),
          const SizedBox(height: 40),
          // buildSection 호출 시 무작위 인덱스와 스크롤 컨트롤러 모두 전달
          buildSection(
            "주요 아티스트",
            "트렌드를 선도하는 아티스트들을 소개합니다",
            artists,
            artistIndexes, // 무작위 인덱스 전달
            _artistScrollController, // 스크롤 컨트롤러 전달
          ),
        ],
      ),
    );
  }
}

void showArtworkInfoDialog(BuildContext context, Artwork item) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(child: Text('이미지 없음')),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '작가: ${item.artist}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (item.highestBid.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '현재가: ${item.highestBid}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, item.link);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("상세보기"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("닫기"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

