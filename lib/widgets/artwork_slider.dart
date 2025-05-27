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
        if (picData['resizedImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${picData['resizedImagePath']}";
        if (picData['thumbnailImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${picData['thumbnailImagePath']}";
        if (picData['originImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${picData['originImagePath']}";
        if (picData['fileName'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${picData['fileName']}";
      } else {
        if (item['resizedImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${item['resizedImagePath']}";
        if (item['thumbnailImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${item['thumbnailImagePath']}";
        if (item['originImagePath'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${item['originImagePath']}";
        if (item['fileName'] != null) return "http://10.100.204.171:8080/ourlog/picture/display/${item['fileName']}";
      }
      return "http://10.100.204.171:8080/ourlog/picture/display/default-image.jpg";
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
  const ArtworkSlider({Key? key}) : super(key: key);

  @override
  State<ArtworkSlider> createState() => _ArtworkSliderState();
}

class _ArtworkSliderState extends State<ArtworkSlider> {
  static const String viewsApiUrl = "http://10.100.204.171:8080/ourlog/ranking?type=views";
  static const String followersApiUrl = "http://10.100.204.171:8080/ourlog/ranking?type=followers";

  List<Artwork> artworks = [];
  List<Artwork> artists = [];

  List<int> artworkIndexes = [];
  List<int> artistIndexes = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchData();

    // 3초마다 랜덤 인덱스 갱신
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        artworkIndexes = getRandomIndexes(artworks.length, 3);
        artistIndexes = getRandomIndexes(artists.length, 3);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<int> getRandomIndexes(int length, int count) {
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
          artworkIndexes = getRandomIndexes(artworks.length, 3);
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
          artistIndexes = getRandomIndexes(artists.length, 3);
        });
      }
    } catch (e) {
      debugPrint("주요 아티스트 불러오기 실패: $e");
    }
  }

  Widget buildSection(String title, String subtitle, List<Artwork> data, List<int> indexes) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // 예: 랭킹 페이지로 이동 (Navigator 사용 가능)
            debugPrint("Go to /ranking");
          },
          child: Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        data.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title == "인기 작품 추천" ? "인기 작품이 없습니다." : "주요 아티스트가 없습니다.",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: indexes.length,
            itemBuilder: (context, idx) {
              final index = indexes[idx];
              if (index >= data.length) return const SizedBox.shrink();
              final item = data[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  child: Container(
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            item.imageUrl,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 140,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.artist,
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.isArtist)
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.followers.toString(),
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (item.highestBid.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.highestBid,
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
          buildSection(
            "인기 작품 추천",
            "사람들의 마음을 사로잡은 그림들을 소개합니다",
            artworks,
            artworkIndexes,
          ),
          buildSection(
            "주요 아티스트",
            "트렌드를 선도하는 아티스트들을 소개합니다",
            artists,
            artistIndexes,
          ),
        ],
      ),
    );
  }
}
