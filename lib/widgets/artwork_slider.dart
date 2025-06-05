import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';


// Artwork 모델 정의 (unchanged)
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

  static const String _baseUrl =
      "http://10.100.204.144:8080/ourlog/picture/display/";

  factory Artwork.fromJson(Map<String, dynamic> json, {bool isArtist = false}) {
    String getImageUrl(Map<String, dynamic> item) {
      if (item['pictureDTOList'] != null && item['pictureDTOList'].isNotEmpty) {
        final picData = item['pictureDTOList'][0];
        if (picData['resizedImagePath'] != null)
          return "$_baseUrl${picData['resizedImagePath']}";
        if (picData['thumbnailImagePath'] != null)
          return "$_baseUrl${picData['thumbnailImagePath']}";
        if (picData['originImagePath'] != null)
          return "$_baseUrl${picData['originImagePath']}";
        if (picData['fileName'] != null)
          return "$_baseUrl${picData['fileName']}";
      } else {
        if (item['resizedImagePath'] != null)
          return "$_baseUrl${item['resizedImagePath']}";
        if (item['thumbnailImagePath'] != null)
          return "$_baseUrl${item['thumbnailImagePath']}";
        if (item['originImagePath'] != null)
          return "$_baseUrl${item['originImagePath']}";
        if (item['fileName'] != null) return "$_baseUrl${item['fileName']}";
      }
      return "${_baseUrl}default-image.jpg";
    }

    String highestBidFormatted = "";
    if (json['tradeDTO'] != null &&
        json['tradeDTO']['highestBid'] != null &&
        num.tryParse(json['tradeDTO']['highestBid'].toString()) != null &&
        num.parse(json['tradeDTO']['highestBid'].toString()) > 0) {
      highestBidFormatted =
      "₩${int.parse(json['tradeDTO']['highestBid'].toString()).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";
    }

    return Artwork(
      imageUrl: getImageUrl(json),
      title: json['title'] ?? (isArtist ? "대표작 없음" : ""),
      artist: json['nickname'] ?? "unknown",
      highestBid: highestBidFormatted,
      link:
      isArtist
          ? (json['userId'] != null
          ? "/worker/${json['userId']}"
          : "/worker/unknown")
          : "/Art/${json['postId']}",
      isArtist: isArtist,
      followers:
      isArtist && json['followers'] != null ? json['followers'] as int : 0,
    );
  }
}

class ArtworkSlider extends StatefulWidget {
  const ArtworkSlider({super.key});

  @override
  State<ArtworkSlider> createState() => _ArtworkSliderState();
}

class _ArtworkSliderState extends State<ArtworkSlider> {
  static const String viewsApiUrl =
      "http://10.100.204.144:8080/ourlog/ranking?type=views";
  static const String followersApiUrl =
      "http://10.100.204.144:8080/ourlog/ranking?type=followers";

  List<Artwork> artworks = [];
  List<Artwork> artists = [];

  Timer? _timer;

  late PageController _artworkPageController;
  late PageController _artistPageController;

  // 현재 PageView 인덱스 추적
  int _currentArtworkPageIndex = 0;
  int _currentArtistPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _artworkPageController = PageController(initialPage: 0);
    _artistPageController = PageController(initialPage: 0);

    fetchData().then((_) {
      if (mounted) {
        setState(() {
          // No need for artworkSet1, artworkSet2, artistSet1, artistSet2 anymore
          // The PageView.builder will directly use the 'artworks' and 'artists' lists
          // with modulo operator for infinite scrolling.
        });
      } else {
        debugPrint('🎨👨‍🎨 initState: mounted == false. setState 호출 스킵.');
      }
    });

    // Simplified listeners: only update current index
    _artworkPageController.addListener(() {
      if (_artworkPageController.page != null) {
        _currentArtworkPageIndex = _artworkPageController.page!.round();
      }
    });
    _artistPageController.addListener(() {
      if (_artistPageController.page != null) {
        _currentArtistPageIndex = _artistPageController.page!.round();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer();
    });
  }

  // Timer 시작 함수
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      // 인기 작품 슬라이드
      if (_artworkPageController.hasClients && artworks.isNotEmpty) {
        if (!_artworkPageController.position.isScrollingNotifier.value) {
          _artworkPageController.animateToPage(
            _currentArtworkPageIndex + 1, // Simply go to the next page
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }

      // 주요 아티스트 슬라이드
      if (_artistPageController.hasClients && artists.isNotEmpty) {
        if (!_artistPageController.position.isScrollingNotifier.value) {
          _artistPageController.animateToPage(
            _currentArtistPageIndex + 1, // Simply go to the next page
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _artworkPageController.dispose();
    _artistPageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final resArtworks = await http.get(Uri.parse(viewsApiUrl));
      if (resArtworks.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtworks.body);
        final mapped = data.map((e) => Artwork.fromJson(e)).toList();
        if (mounted) {
          setState(() {
            artworks = mapped;
          });
        }
      }
    } catch (e) {
      debugPrint("인기 작품 불러오기 실패: $e");
    }

    try {
      final resArtists = await http.get(Uri.parse(followersApiUrl));
      if (resArtists.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtists.body);

        final Map<String, Artwork> uniqueArtistsMap = {};
        for (var item in data) {
          final artwork = Artwork.fromJson(item, isArtist: true);
          // Ensure uniqueness based on artist nickname if multiple artworks by same artist appear
          if (!uniqueArtistsMap.containsKey(artwork.artist)) {
            uniqueArtistsMap[artwork.artist] = artwork;
          }
        }
        final List<Artwork> uniqueArtists = uniqueArtistsMap.values.toList();

        if (mounted) {
          setState(() {
            artists = uniqueArtists;
          });
        }
      } else {
        debugPrint('주요 아티스트 불러오기 실패: 상태 코드 ${resArtists.statusCode}');
      }
    } catch (e) {
      debugPrint("주요 아티스트 불러오기 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: '인기 작품',
            subtitle: '사람들의 마음을 사로잡은 그림들을 소개합니다',
            controller: _artworkPageController,
            onPageChanged: (index) {
              setState(() {
                _currentArtworkPageIndex = index;
              });
            },
            isArtist: false,
            originalList: artworks,
          ),
          const SizedBox(height: 32),
          _buildSection(
            title: '주요 아티스트',
            subtitle: '트렌드를 선도하는 아티스트들을 소개합니다',
            controller: _artistPageController,
            onPageChanged: (index) {
              setState(() {
                _currentArtistPageIndex = index;
              });
            },
            isArtist: true,
            originalList: artists,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required PageController controller,
    required Function(int) onPageChanged,
    required bool isArtist,
    required List<Artwork> originalList,
  }) {
    if (originalList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 50),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 50),
              Text(
                title == "인기 작품" ? "아직 인기 작품이 없습니다." : "아직 주요 아티스트가 없습니다.",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/ranking');
            },
            child: Text(
              title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              subtitle!,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),
        ],
        const SizedBox(height: 50),

        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            // Set itemCount to a very large number for infinite scrolling
            itemCount: originalList.length > 0 ? 1000000 : 0,
            itemBuilder: (context, index) {
              final item = originalList[index % originalList.length];

              return Center(
                child: GestureDetector(
                  onTap: () async {
                    _timer?.cancel();
                    await showArtworkInfoDialog(context, item);
                    startTimer();
                  },
                  child: Container(
                    width: 350,
                    height: 350,
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
                      borderRadius: BorderRadius.circular(0),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showArtworkInfoDialog(BuildContext context, Artwork item) async {
  await showDialog(
    context: context,
    builder: (dialogContext) {
      final authProvider = Provider.of<AuthProvider>(dialogContext, listen: false);

      // ✨ 현재 화면 높이의 일부를 이미지 높이로 설정
      final screenHeight = MediaQuery.of(dialogContext).size.height;
      final imageHeight = screenHeight * 0.35; // 화면 높이의 35%를 이미지 높이로 설정 (원하는 비율로 조절)
      // 예를 들어, 화면 높이가 800px이면 이미지 높이는 280px이 됩니다.

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
                    height: imageHeight, // ✨ 반응형 높이 적용
                    fit: BoxFit.cover, // ✨ 이미지가 지정된 공간을 채우도록 설정
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: imageHeight, // ✨ 에러 이미지도 동일한 반응형 높이로 설정
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
                        if (!authProvider.isLoggedIn) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: const Text('로그인이 필요합니다. 로그인 페이지로 이동합니다.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          });
                          return;
                        }

                        Navigator.pop(dialogContext);
                        final currentUserId = authProvider.userId;

                        if (item.isArtist) {
                          print("Tapped!");
                          final userIdFromLink = item.link.split('/').last;
                          print("Extracted userId: $userIdFromLink");
                          Navigator.pushNamed(
                            dialogContext,
                            '/worker',
                            arguments: {
                              'userId': userIdFromLink,
                              'currentUserId': currentUserId,
                            },
                          );
                        } else {
                          Navigator.pushNamed(
                            dialogContext,
                            '/Art',
                            arguments:
                            item.link.length > 0
                                ? item.link.split('/').last
                                : '',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(item.isArtist ? "작가프로필보기" : "작품상세보기"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
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