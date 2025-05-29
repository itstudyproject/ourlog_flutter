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

  static const String _baseUrl = "http://10.100.204.54:8080/ourlog/picture/display/";

  factory Artwork.fromJson(Map<String, dynamic> json, {bool isArtist = false}) {
    String getImageUrl(Map<String, dynamic> item) {
      if (item['pictureDTOList'] != null && item['pictureDTOList'].isNotEmpty) {
        final picData = item['pictureDTOList'][0];
        if (picData['resizedImagePath'] != null) return "$_baseUrl${picData['resizedImagePath']}";
        if (picData['thumbnailImagePath'] != null) return "$_baseUrl${picData['thumbnailImagePath']}";
        if (picData['originImagePath'] != null) return "$_baseUrl${picData['originImagePath']}";
        if (picData['fileName'] != null) return "$_baseUrl${picData['fileName']}";
      } else {
        if (item['resizedImagePath'] != null) return "$_baseUrl${item['resizedImagePath']}";
        if (item['thumbnailImagePath'] != null) return "$_baseUrl${item['thumbnailImagePath']}";
        if (item['originImagePath'] != null) return "$_baseUrl${item['originImagePath']}";
        if (item['fileName'] != null) return "$_baseUrl${item['fileName']}";
      }
      return "${_baseUrl}default-image.jpg";
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

  // ✅ 수정: 슬라이드 복제 리스트는 PageView용으로 사용 (실제 데이터 + 양 끝 복제)
  List<Artwork> extendedArtworks = [];
  List<Artwork> extendedArtists = [];

  // ✅ 수정: 화면에 표시될 무작위 Artwork 항목들을 저장하는 리스트
  List<Artwork> displayedArtworks = [];
  List<Artwork> displayedArtists = [];


  Timer? _timer;

  // PageController 유지 및 초기 페이지 설정
  final PageController _artworkPageController = PageController(initialPage: 1); // 초기 페이지를 복제된 첫 항목 다음인 1로 설정
  final PageController _artistPageController = PageController(initialPage: 1); // 초기 페이지를 복제된 첫 항목 다음인 1로 설정

  // 현재 PageView 인덱스 추적 (리스너에서 사용)
  int _currentArtworkPageIndex = 1;
  int _currentArtistPageIndex = 1;

  static const int _displayCount = 3; // 한 번에 보여줄 항목 수

  @override
  void initState() {
    super.initState();
    fetchData().then((_) {
      // 데이터 로드 후 extended 리스트 및 초기 displayed 리스트 설정
      if (mounted) {
        setState(() {
          // 데이터가 2개 이상일 때만 복제 리스트 생성
          if (artworks.length >= 2) {
            extendedArtworks = [
              artworks.last, // 마지막 항목 복제
              ...artworks,   // 원본 항목들
              artworks.first,// 첫 번째 항목 복제
            ];
          } else {
            extendedArtworks = List.from(artworks); // 데이터 부족 시 복제 없이 원본 사용
          }

          if (artists.length >= 2) {
            extendedArtists = [
              artists.last,  // 마지막 항목 복제
              ...artists,    // 원본 항목들
              artists.first, // 첫 번째 항목 복제
            ];
          } else {
            extendedArtists = List.from(artists); // 데이터 부족 시 복제 없이 원본 사용
          }

          // ✅ 초기 displayed 리스트 설정 (무작위 항목 선택)
          displayedArtworks = getRandomArtworks(artworks, _displayCount);
          displayedArtists = getRandomArtworks(artists, _displayCount);
        });

        // PageView 리스너 추가: 부드러운 무한 스크롤 효과 구현
        _artworkPageController.addListener(_artworkPageListener);
        _artistPageController.addListener(_artistPageListener);

        // Timer 동작: PageView 애니메이션 및 displayed 리스트 갱신 (그림 변경)
        startTimer(); // Timer 시작 함수 호출
      }
    });
  }

  // PageView 리스너 함수 분리
  void _artworkPageListener() {
    if (_artworkPageController.page == null) return;
    // jumpToPage는 애니메이션 없이 즉시 이동
    if (_artworkPageController.page == extendedArtworks.length - 1 && extendedArtworks.length > 1) {
      // 마지막 복제 항목에 도달하면 첫 번째 원본 항목으로 순간 이동
      // jumpToPage에는 duration과 curve 매개변수 없음
      _artworkPageController.jumpToPage(1);
      _currentArtworkPageIndex = 1;
    } else if (_artworkPageController.page == 0 && extendedArtworks.length > 1) {
      // 첫 번째 복제 항목에 도달하면 마지막 원본 항목으로 순간 이동
      // jumpToPage에는 duration과 curve 매개변수 없음
      _artworkPageController.jumpToPage(extendedArtworks.length - 2);
      _currentArtworkPageIndex = extendedArtworks.length - 2;
    } else {
      _currentArtworkPageIndex = _artworkPageController.page!.round();
    }
  }

  void _artistPageListener() {
    if (_artistPageController.page == null) return;
    // jumpToPage는 애니메이션 없이 즉시 이동
    if (_artistPageController.page == extendedArtists.length - 1 && extendedArtists.length > 1) {
      // 마지막 복제 항목에 도달하면 첫 번째 원본 항목으로 순간 이동
      // jumpToPage에는 duration과 curve 매개변수 없음
      _artistPageController.jumpToPage(1);
      _currentArtistPageIndex = 1;
    } else if (_artistPageController.page == 0 && extendedArtists.length > 1) {
      // 첫 번째 복제 항목에 도달하면 마지막 원본 항목으로 순간 이동
      // jumpToPage에는 duration과 curve 매개변수 없음
      _artistPageController.jumpToPage(extendedArtists.length - 2);
      _currentArtistPageIndex = extendedArtists.length - 2;
    } else {
      _currentArtistPageIndex = _artistPageController.page!.round();
    }
  }


  // ✅ 수정: Timer 시작 함수 - displayed 리스트 업데이트 및 PageView 애니메이션
  void startTimer() {
    _timer?.cancel(); // 기존 타이머가 있다면 취소
    _timer = Timer.periodic(const Duration(seconds: 3), (_) { // 3초마다 실행
      if (!mounted) return; // 위젯이 해제되면 타이머 중지

      // 인기 작품 슬라이드
      if (extendedArtworks.length > 1) { // 복제 항목 포함 2개 이상일 때만 슬라이드
        _artworkPageController.animateToPage(
          // 다음 페이지로 이동. 리스너에서 순간 이동 처리하므로 인덱스 + 1
          (_currentArtworkPageIndex + 1),
          duration: const Duration(milliseconds: 800), // 애니메이션 시간
          curve: Curves.easeInOut, // 애니메이션 커브
        );

        // ✅ displayedArtworks 리스트를 무작위 항목으로 갱신 (그림 변경)
        setState(() {
          displayedArtworks = getRandomArtworks(artworks, _displayCount);
        });
      }

      // 주요 아티스트 슬라이드
      if (extendedArtists.length > 1) { // 복제 항목 포함 2개 이상일 때만 슬라이드
        _artistPageController.animateToPage(
          // 다음 페이지로 이동. 리스너에서 순간 이동 처리하므로 인덱스 + 1
          (_currentArtistPageIndex + 1),
          duration: const Duration(milliseconds: 800), // 애니메이션 시간
          curve: Curves.easeInOut, // 애니메이션 커브
        );

        // ✅ displayedArtists 리스트를 무작위 항목으로 갱신 (그림 변경)
        setState(() {
          displayedArtists = getRandomArtworks(artists, _displayCount);
        });
      }
    });
  }


  @override
  void dispose() {
    _timer?.cancel(); // 타이머 해제
    _artworkPageController.removeListener(_artworkPageListener); // 리스너 해제
    _artistPageController.removeListener(_artistPageListener); // 리스너 해제
    _artworkPageController.dispose(); // PageController 해제
    _artistPageController.dispose(); // PageController 해제
    super.dispose();
  }

  // ✅ 수정: 무작위 Artwork 항목을 선택하는 함수
  List<Artwork> getRandomArtworks(List<Artwork> sourceList, int count) {
    if (sourceList.isEmpty) return [];
    final List<Artwork> randomList = [];
    final maxCount = sourceList.length < count ? sourceList.length : count;
    final random = Random();
    final List<int> usedIndexes = []; // 중복 방지를 위해 사용된 인덱스 저장

    while (randomList.length < maxCount) {
      final randIndex = random.nextInt(sourceList.length);
      if (!usedIndexes.contains(randIndex)) {
        randomList.add(sourceList[randIndex]);
        usedIndexes.add(randIndex);
      }
    }
    return randomList;
  }

  Future<void> fetchData() async {
    // 기존 fetchData 함수 로직 유지 (데이터 로드만 수행)
    try {
      final resArtworks = await http.get(Uri.parse(viewsApiUrl));
      if (resArtworks.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtworks.body);
        final mapped = data.map((e) => Artwork.fromJson(e)).toList();
        if (mounted) {
          setState(() {
            artworks = mapped;
            // ✅ 데이터 로드 후 초기 displayed 리스트 설정은 initState에서 하도록 변경됨
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
        final mapped = data.map((e) => Artwork.fromJson(e, isArtist: true)).toList();
        if (mounted) {
          setState(() {
            artists = mapped;
            // ✅ 데이터 로드 후 초기 displayed 리스트 설정은 initState에서 하도록 변경됨
          });
        }
      }
    } catch (e) {
      debugPrint("주요 아티스트 불러오기 실패: $e");
    }
  }

  // buildSection 함수 (PageView 사용 및 displayed 리스트 사용)
  Widget buildSection(String title, String subtitle, List<Artwork> data, List<Artwork> extendedData, List<Artwork> displayedData, PageController controller) {
    // ✅ 수정: 데이터 로딩 중이거나 표시할 데이터가 없을 때 메시지 표시
    if (data.isEmpty) { // 원본 데이터가 비어있으면 로딩 중
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "데이터를 불러오는 중입니다...", // 로딩 중 메시지
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (displayedData.isEmpty) { // 원본 데이터는 있지만 표시할 무작위 데이터가 없는 경우
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title == "인기 작품 추천" ? "인기 작품이 없습니다." : "주요 아티스트가 없습니다.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 데이터가 있지만 extendedData가 비어있는 경우 (데이터가 2개 미만이어서 복제가 안된 경우)
    if (extendedData.isEmpty && data.isNotEmpty) {
      extendedData = List.from(data); // 이 경우 원본 데이터를 extendedData로 사용
    }


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
        SizedBox(
          height: 400,
          // ListView 대신 PageView 사용
          child: PageView.builder(
            controller: controller, // PageController 연결
            itemCount: extendedData.length, // 복제된 데이터 리스트 길이 사용
            itemBuilder: (context, index) {
              // ✅ 수정: extendedData의 index를 사용하여 표시될 displayedData 리스트의 인덱스를 계산
              // PageView는 extendedData를 순회하므로, 각 페이지에 displayedData의 항목을 매핑해야 합니다.
              // 복제된 항목(0번째와 마지막 항목) 처리 필요
              int displayedDataIndex;
              if (extendedData.length > data.length) { // 복제된 데이터가 있는 경우
                if (index == 0) { // 복제된 첫 항목은 displayedData의 마지막 항목에 해당 (표시용)
                  displayedDataIndex = displayedData.length > 0 ? displayedData.length - 1 : -1;
                } else if (index == extendedData.length - 1) { // 복제된 마지막 항목은 displayedData의 첫 항목에 해당 (표시용)
                  displayedDataIndex = displayedData.length > 0 ? 0 : -1;
                } else { // 원본 항목 범위 (index 1 ~ extendedData.length - 2)
                  // 이 인덱스를 displayedData의 인덱스 범위로 변환
                  // displayedData는 _displayCount 길이이므로 modulo 연산 등을 사용
                  // 간단하게는 index - 1을 _displayCount로 나눈 나머지 사용
                  displayedDataIndex = (index - 1) % displayedData.length;
                }
              } else { // 복제된 데이터가 없는 경우 (데이터가 2개 미만)
                displayedDataIndex = index; // extendedData와 displayedData의 길이가 같음
              }


              // ✅ 수정: displayedData 리스트에서 해당 인덱스의 Artwork 항목 사용
              final item = (displayedDataIndex >= 0 && displayedDataIndex < displayedData.length)
                  ? displayedData[displayedDataIndex]
                  : null; // 유효하지 않으면 null


              // 항목이 유효하지 않으면 빈 위젯 반환 (오류 상황)
              if (item == null) {
                return Container(
                  width: 350, // PageView 내 항목의 너비
                  height: 350, // PageView 내 항목의 높이
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
                  child: const Center(child: Text('항목 표시 오류', style: TextStyle(color: Colors.red),)),
                );
              }


              return Center( // PageView 중앙에 오도록 Center 추가
                child: GestureDetector(
                  onTap: () async { // async 키워드 추가
                    // 다이얼로그를 띄우기 전에 타이머 중지
                    _timer?.cancel();

                    // 다이얼로그는 현재 표시된 item 정보를 사용
                    await showArtworkInfoDialog(context, item); // await 키워드 추가

                    // 다이얼로그가 닫힌 후 타이머 다시 시작
                    startTimer();
                  },
                  child: Container(
                    width: 350, // PageView 내 항목의 너비
                    height: 350, // PageView 내 항목의 높이
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
                      borderRadius: BorderRadius.circular(0), // 모서리 둥글기 필요 시 조절
                      child: Image.network(
                        item.imageUrl, // ✅ 수정: displayedData에서 가져온 item의 imageUrl 사용
                        fit: BoxFit.cover, // 이미지 표시 방식
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
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
          // buildSection 호출 시 displayed 리스트 추가 전달
          buildSection(
            "인기 작품 추천",
            "사람들의 마음을 사로잡은 그림들을 소개합니다",
            artworks, // 원본 데이터
            extendedArtworks, // PageView용 복제 데이터
            displayedArtworks, // ✅ 표시될 무작위 데이터
            _artworkPageController, // PageController 전달
          ),
          const SizedBox(height: 40),
          // buildSection 호출 시 displayed 리스트 추가 전달
          buildSection(
            "주요 아티스트",
            "트렌드를 선도하는 아티스트들을 소개합니다",
            artists, // 원본 데이터
            extendedArtists, // PageView용 복제 데이터
            displayedArtists, // ✅ 표시될 무작위 데이터
            _artistPageController, // PageController 전달
          ),
        ],
      ),
    );
  }
}

Future<void> showArtworkInfoDialog(BuildContext context, Artwork item) async {
  await showDialog(
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

