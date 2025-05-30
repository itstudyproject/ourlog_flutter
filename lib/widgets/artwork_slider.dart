import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

  // ✅ 수정: 표시할 랜덤 목록
  List<Artwork> displayedList = [];

  // ✅ 수정: 랜덤 개수를 3으로 고정
  static const int _randomCount = 3;

  Timer? _timer;

  // PageController 유지 및 초기 페이지 설정
  late PageController _artworkPageController;
  late PageController _artistPageController;

  // 현재 PageView 인덱스 추적
  int _currentPageIndex = 1;

  // ✅ 추가: 현재 사이클의 시작 인덱스 추적
  int _currentRandomStart = 0;

  // ✅ 수정: 현재 표시 중인 전체 랜덤 목록 (이제 두 개의 세트로 관리)
  List<Artwork> currentArtworkDisplayList = [];
  List<Artwork> currentArtistDisplayList = [];

  // ✅ 추가: 슬라이더 표시를 위한 두 개의 아이템 세트
  List<Artwork> artworkSet1 = [];
  List<Artwork> artworkSet2 = [];
  List<Artwork> artistSet1 = [];
  List<Artwork> artistSet2 = [];

  // ✅ 추가: 현재 페이지 인덱스
  int _currentArtworkPageIndex = 0;
  int _currentArtistPageIndex = 0;

  // ✅ 수정: 아티스트 관련 변수들 (중복 제거)
  // List<Artwork> displayedArtists1 = []; // 더 이상 사용 안함
  // List<Artwork> displayedArtists2 = []; // 더 이상 사용 안함

  // ✅ 추가: 중복 없이 랜덤 항목 선택 함수
  List<T> getUniqueRandomItems<T>(List<T> sourceList, int count, {List<T> excludeItems = const []}) {
    if (sourceList.isEmpty || count <= 0) return [];

    // 제외할 항목 목록을 Set으로 변환하여 검색 성능 최적화
    final excludeSet = excludeItems.toSet();

    // 제외 항목을 제외한 실제 사용 가능한 항목 목록 생성
    final availableItems = sourceList.where((item) => !excludeSet.contains(item)).toList();

    if (count > availableItems.length) {
      debugPrint('⚠️ 경고: 요청된 항목 수($count)가 제외 항목을 제외한 원본 목록 크기(${availableItems.length})보다 큽니다. 사용 가능한 전체 목록을 반환합니다.');
      // 요청된 수가 사용 가능한 목록 크기보다 크면 사용 가능한 전체 반환
      return availableItems;
    }

    final random = Random();
    final List<T> shuffled = List<T>.from(availableItems)..shuffle(random);
    return shuffled.take(count).toList(); // 요청된 개수만큼 반환
  }

  // ✅ 수정: PageView 리스너 - 내용 업데이트 및 점프 로직
  void _artworkPageListener() {
    if (_artworkPageController.page == null) return;

    // 페이지 값이 변경될 때마다 리스너가 호출되므로, 정수 페이지에 도달했을 때만 로직 실행
    if (_artworkPageController.page! % 1.0 == 0) {
      final page = _artworkPageController.page!.round();

      // 현재 페이지 인덱스 업데이트
      _currentArtworkPageIndex = page;
      // debugPrint('🎨 인기 작품 - 정수 페이지 도달, 현재 인덱스 업데이트: $page'); // 디버그용

      // ✅ 수정: 인덱스 3에 도달 시 (두 번째 세트의 시작) Set1 업데이트 및 0으로 즉시 점프
      if (page == 3) {
        debugPrint('🎨 인기 작품 - 인덱스 3 도달, Set1 업데이트 및 0으로 즉시 점프');
        setState(() {
          // Set1을 Set2 내용으로 교체 (이전 set2의 내용이 새로운 set1이 됨)
          artworkSet1 = [...artworkSet2];
          // Set2는 Set1과 중복되지 않는 새로운 랜덤 3개 항목으로 업데이트
          artworkSet2 = getUniqueRandomItems(artworks, _randomCount, excludeItems: artworkSet1);
        });
        // 인덱스 0으로 즉시 이동 (애니메이션 없음)
        _artworkPageController.jumpToPage(0);
        _currentArtworkPageIndex = 0; // 점프 후 인덱스 업데이트
        debugPrint('🎨 인기 작품 - Set1 업데이트 및 0으로 점프 완료');
      }
      // ✅ 수정: 인덱스 0에 도달 시 (뒤로 스크롤 감지) Set2 업데이트 및 3으로 즉시 점프
      else if (page == 0 && _artworkPageController.position.activity is! IdleScrollActivity) {
        // IdleActivity가 아닐 때만 실행하여 jumpToPage(0)에 의해 발생하는 리스너 호출 무시
        debugPrint('🎨 인기 작품 - 인덱스 0 도달 (뒤로 스크롤 감지), Set2 업데이트 및 3으로 즉시 점프');
        setState(() {
          // Set2를 Set1 내용으로 교체 (이전 set1의 내용이 새로운 set2가 됨)
          artworkSet2 = [...artworkSet1];
          // Set1은 Set2와 중복되지 않는 새로운 랜덤 3개 항목으로 업데이트
          artworkSet1 = getUniqueRandomItems(artworks, _randomCount, excludeItems: artworkSet2);
        });
        // 인덱스 3으로 즉시 이동
        _artworkPageController.jumpToPage(3);
        _currentArtworkPageIndex = 3; // 점프 후 인덱스 업데이트
        debugPrint('🎨 인기 작품 - Set2 업데이트 및 3으로 점프 완료');
      }
      // 그 외 일반 페이지 전환 시 인덱스 업데이트
    }
  }

  // ✅ 수정: PageView 리스너 - 내용 업데이트 및 점프 로직
  void _artistPageListener() {
    if (_artistPageController.page == null) return;

    // 페이지 값이 변경될 때마다 리스너가 호출되므로, 정수 페이지에 도달했을 때만 로직 실행
    if (_artistPageController.page! % 1.0 == 0) {
      final page = _artistPageController.page!.round();

      // 현재 페이지 인덱스 업데이트
      _currentArtistPageIndex = page;
      // debugPrint('👨‍🎨 주요 아티스트 - 정수 페이지 도달, 현재 인덱스 업데이트: $page'); // 디버그용

      // ✅ 수정: 인덱스 3에 도달 시 (두 번째 세트의 시작) Set1 업데이트 및 0으로 즉시 점프
      if (page == 3) {
        debugPrint('👨‍🎨 주요 아티스트 - 인덱스 3 도달, Set1 업데이트 및 0으로 즉시 점프');
        setState(() {
          // Set1을 Set2 내용으로 교체 (이전 set2의 내용이 새로운 set1이 됨)
          artistSet1 = [...artistSet2];
          // Set2는 Set1과 중복되지 않는 새로운 랜덤 3개 항목으로 업데이트
          artistSet2 = getUniqueRandomItems(artists, _randomCount, excludeItems: artistSet1);
        });
        // 인덱스 0으로 즉시 이동 (애니메이션 없음)
        _artistPageController.jumpToPage(0);
        _currentArtistPageIndex = 0; // 점프 후 인덱스 업데이트
        debugPrint('👨‍🎨 주요 아티스트 - Set1 업데이트 및 0으로 점프 완료');

      }
      // ✅ 수정: 인덱스 0에 도달 시 (뒤로 스크롤 감지) Set2 업데이트 및 3으로 즉시 점프
      else if (page == 0 && _artistPageController.position.activity is! IdleScrollActivity) {
        // IdleActivity가 아닐 때만 실행하여 jumpToPage(0)에 의해 발생하는 리스너 호출 무시
        debugPrint('👨‍🎨 주요 아티스트 - 인덱스 0 도달 (뒤로 스크롤 감지), Set2 업데이트 및 3으로 즉시 점프');
        setState(() {
          // Set2를 Set1 내용으로 교체 (이전 set1의 내용이 새로운 set2가 됨)
          artistSet2 = [...artistSet1];
          // Set1은 Set2와 중복되지 않는 새로운 랜덤 3개 항목으로 업데이트
          artistSet1 = getUniqueRandomItems(artists, _randomCount, excludeItems: artistSet2);
        });
        // 인덱스 3으로 즉시 이동
        _artistPageController.jumpToPage(3);
        _currentArtistPageIndex = 3; // 점프 후 인덱스 업데이트
        debugPrint('👨‍🎨 주요 아티스트 - Set2 업데이트 및 3으로 점프 완료');
      }
      // 그 외 일반 페이지 전환 시 인덱스 업데이트
    }
  }

  @override
  void initState() {
    super.initState();
    // PageController 초기화
    _artworkPageController = PageController(initialPage: 0);
    _artistPageController = PageController(initialPage: 0);

    // 데이터 로드 후 초기화
    fetchData().then((_) {
      if (mounted) {
        setState(() {
          // ✅ 수정: 인기 작품 초기화 - 중복 없는 6개 항목 선택 후 두 개의 세트로 나눔
          final initialArtworks = getUniqueRandomItems(artworks, 6);
          artworkSet1 = initialArtworks.take(3).toList();
          artworkSet2 = initialArtworks.skip(3).take(3).toList();

          // ✅ 수정: 아티스트 초기화 - 중복 없는 6개 항목 선택 후 두 개의 세트로 나눔
          final initialArtists = getUniqueRandomItems(artists, 6);
          artistSet1 = initialArtists.take(3).toList();
          artistSet2 = initialArtists.skip(3).take(3).toList();

          // 기존의 displayedList, currentArtworkDisplayList, currentArtistDisplayList, extendedArtworks, extendedArtists 변수는 더 이상 사용하지 않음
        });
      } else {
        debugPrint('🎨👨‍🎨 initState: mounted == false. setState 호출 스킵.');
      }
    });

    _artworkPageController.addListener(_artworkPageListener);
    _artistPageController.addListener(_artistPageListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTimer();
    });
  }

  // ✅ 수정: Timer 시작 함수 (인덱스 계산 로직 수정)
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      // 인기 작품 슬라이드
      // 0, 1, 2 -> 1, 2, 3 (리스너에서 3 도달 감지 후 처리)
      // 3, 4, 5 -> 4, 5 (다음 애니메이션은 리스너에서 3으로 점프 후 0, 1, 2로 이어짐)
      if (_artworkPageController.hasClients) {
        final nextPage = (_currentArtworkPageIndex + 1) % 6; // 전체 6페이지 기준으로 다음 페이지 계산
        debugPrint('🎨 인기 작품 - 타이머: 다음 페이지 (${nextPage})로 이동 (현재 ${_currentArtworkPageIndex})');
        _artworkPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }

      // ✅ 주요 아티스트 슬라이드
      if (_artistPageController.hasClients) {
        final nextPage = (_currentArtistPageIndex + 1) % 6; // 전체 6페이지 기준으로 다음 페이지 계산
        debugPrint('👨‍🎨 주요 아티스트 - 타이머: 다음 페이지 (${nextPage})로 이동 (현재 ${_currentArtistPageIndex})');
        _artistPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _artworkPageController.removeListener(_artworkPageListener);
    _artistPageController.removeListener(_artistPageListener);
    _artworkPageController.dispose();
    _artistPageController.dispose();
    _timer?.cancel();
    super.dispose();
  }


  Future<void> fetchData() async {
    // 기존 fetchData 함수 로직 유지 (데이터 로드만 수행)
    try {
      final resArtworks = await http.get(Uri.parse(viewsApiUrl));
      if (resArtworks.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resArtworks.body);
        final mapped = data.map((e) => Artwork.fromJson(e)).toList();
        // ✅ 수정: 데이터 로드 후 artworkSet1, artworkSet2 초기화 (중복 없는 6개)
        if (mounted) {
          setState(() {
            artworks = mapped;
            if (artworks.length >= 6) {
              final initialArtworks = getUniqueRandomItems(artworks, 6);
              artworkSet1 = initialArtworks.take(3).toList();
              artworkSet2 = initialArtworks.skip(3).take(3).toList();
            } else { // 데이터가 6개 미만일 경우 처리
              artworkSet1 = List<Artwork>.from(artworks);
              artworkSet2 = []; // 두 번째 세트는 비워둡니다.
            }
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
        // ✅ 수정: 데이터 로드 후 artistSet1, artistSet2 초기화 (중복 없는 6개)
        if (mounted) {
          setState(() {
            artists = mapped;
            if (artists.length >= 6) {
              final initialArtists = getUniqueRandomItems(artists, 6);
              artistSet1 = initialArtists.take(3).toList();
              artistSet2 = initialArtists.skip(3).take(3).toList();
            } else { // 데이터가 6개 미만일 경우 처리
              artistSet1 = List<Artwork>.from(artists);
              artistSet2 = []; // 두 번째 세트는 비워둡니다.
            }
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
    // ✅ 수정: items 리스트는 더 이상 buildSection에서 사용되지 않음
    // currentArtworkDisplayList, currentArtistDisplayList 변수는 제거됨
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 수정: 인기 작품 섹션 - items 리스트를 직접 전달하지 않음
          _buildSection(
            title: '인기 작품',
            // items: currentArtworkDisplayList, // 더 이상 사용 안함
            controller: _artworkPageController,
            onPageChanged: (index) {
              setState(() {
                _currentArtworkPageIndex = index;
              });
            },
            isArtist: false,
          ),
          const SizedBox(height: 32),
          // ✅ 수정: 메인 작가 섹션 - items 리스트를 직접 전달하지 않음
          _buildSection(
            title: '메인 작가',
            // items: currentArtistDisplayList, // 더 이상 사용 안함
            controller: _artistPageController,
            onPageChanged: (index) {
              setState(() {
                _currentArtistPageIndex = index;
              });
            },
            isArtist: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    // required List<Artwork> items, // 더 이상 items 리스트를 직접 받지 않음
    required PageController controller,
    required Function(int) onPageChanged,
    required bool isArtist,
  }) {
    // ✅ 수정: items 리스트 대신 isArtist에 따라 적절한 세트 리스트 사용
    final List<Artwork> set1 = isArtist ? artistSet1 : artworkSet1;
    final List<Artwork> set2 = isArtist ? artistSet2 : artworkSet2;

    // 두 세트 중 하나라도 비어있으면 (초기 로딩 전 등) 빈 컨테이너 반환
    if (set1.isEmpty) {
      return Container();
    }

    // ✅ 수정: itemCount를 6으로 고정
    const int pageViewItemCount = 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            // ✅ 수정: itemCount를 6으로 고정
            itemCount: pageViewItemCount,
            itemBuilder: (context, index) {
              // ✅ 수정: 인덱스에 따라 Set1 또는 Set2에서 아이템 가져오기
              Artwork item;
              if (index >= 0 && index < 3) { // 첫 번째 세트 (인덱스 0, 1, 2)
                if (index >= set1.length) { // 안전 장치
                  debugPrint('🚫 오류: Set1 인덱스 범위를 벗어남: $index');
                  return Container();
                }
                item = set1[index];
              } else if (index >= 3 && index < 6) { // 두 번째 세트 (인덱스 3, 4, 5)
                if (index - 3 >= set2.length) { // 안전 장치
                  debugPrint('🚫 오류: Set2 인덱스 범위를 벗어남: ${index - 3}');
                  return Container();
                }
                item = set2[index - 3];
              } else { // 예상치 못한 인덱스
                debugPrint('🚫 오류: 예상치 못한 PageView 인덱스: $index');
                return Container();
              }

              // ✅ 수정: items 리스트 인덱스 범위 검사 로직 변경
              // 기존 로직 제거
              // if (itemIndex < 0 || itemIndex >= items.length) {
              //    debugPrint('🚫 오류: items 리스트 인덱스 범위를 벗어남: $itemIndex, index: $index, itemCount: $pageViewItemCount, items.length: ${items.length}');
              //    // 유효하지 않은 인덱스일 경우 빈 컨테이너 반환
              //    return Container();
              // }

              // 기존의 _buildArtworkCard 호출 로직 유지
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40), // 이미지 로드 실패 시 표시할 아이콘
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

  Widget _buildArtworkCard(Artwork item, bool isArtist) {
    return GestureDetector(
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
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 40), // 이미지 로드 실패 시 표시할 아이콘
            ),
          ),
        ),
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
                        final currentUserId = Provider.of<AuthProvider>(context, listen: false).userId;

                        if (item.isArtist) {
                          // 주요 아티스트인 경우
                          Navigator.pushNamed(
                            context,
                            '/worker',
                            arguments: {
                              'userId': item.link.split('/').last,
                              'currentUserId': currentUserId,
                            },
                          );
                        } else {
                          // 인기 작품인 경우
                          Navigator.pushNamed(
                            context,
                            '/Art',
                            arguments: item.link.length > 0 ? item.link.split('/').last : '',
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

