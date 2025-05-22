import 'package:flutter/material.dart';
import '../models/artwork.dart';
import '../services/artwork_service.dart';
import '../constants/theme.dart';
import 'package:intl/intl.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Artwork> _artworks;
  bool _isLoading = true;
  int _currentSlideIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadArtworks();

    // 자동 슬라이드를 위한 타이머 설정
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (!mounted) return;

    setState(() {
      _currentSlideIndex =
          (_currentSlideIndex + 1) %
          (_artworks.length > 3 ? 3 : _artworks.length);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    // 다음 슬라이드를 위한 타이머 설정
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  void _loadArtworks() {
    // 아트워크 데이터 로드 (실제로는 API 호출 등으로 대체)
    setState(() {
      _isLoading = true;
    });

    // 딜레이를 주어 로딩 효과 구현 (실제 앱에서는 필요 없음)
    Future.delayed(const Duration(milliseconds: 500), () {
      _artworks = ArtworkService.getArtworks();
      setState(() {
        _isLoading = false;
      });
    });
  }

  // void addCustomFont() async {
  //   var fontFamily = FontLoader('NanumSquareNeo');
  //   fontFamily.addFont(loadFont());
  //   await fontFamily.load();
  // }
  //
  // Future<ByteData> loadFont(String font) async {
  //   try {
  //     final response = await http.get(
  //         Uri.parse('https://hangeul.pstatic.net/hangeul_static/css/nanum-square-neo.css'));
  //     if (response.statusCode == 200) {
  //       return ByteData.view(response.bodyBytes.buffer);
  //     } else {
  //       throw Exception('Failed to load font');
  //     }
  //   } catch (e) {
  //     throw Exception(e);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 헤더
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: const Header(key: Key('header')),
                    ),

                    // 메인 컨텐츠
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _loadArtworks();
                        },
                        color: AppTheme.primaryColor,
                        backgroundColor: Colors.black,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMainBanner(),
                              _buildArtworkSlider(),
                              _buildBulletinBoard(),

                              // 푸터
                              const Footer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMainBanner() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbanner1.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // 내용
          Positioned(
            left: 120,
            bottom: 40,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'NanumSquareNeo',
                      ),
                      children: const [TextSpan(text: 'OurLog')],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '당신의 이야기가 작품이 되는 곳',
                    style: TextStyle(fontSize: 9, fontFamily: 'NanumSquareNeo'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '아티스트와 컬렉터가 만나는 특별한 공간',
                    style: TextStyle(fontSize: 9, fontFamily: 'NanumSquareNeo'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkSlider() {
    if (_artworks.isEmpty) return const SizedBox();

    // 인기 작품 3개 선택
    final popularArtworks = _artworks.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            '인기 작품 추천',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '사람들의 마음을 사로잡은 그림들을 소개합니다',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 500,
            child: PageView.builder(
              controller: _pageController,
              itemCount: popularArtworks.length,
              onPageChanged: (index) {
                setState(() {
                  _currentSlideIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildArtworkSlide(popularArtworks[index]);
              },
            ),
          ),
          const SizedBox(height: 20),
          // 페이지 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              popularArtworks.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentSlideIndex == index
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            '주요 아티스트',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '트렌드를 선도하는 아티스트들을 소개합니다',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          _buildArtistGrid(),
        ],
      ),
    );
  }

  Widget _buildArtworkSlide(Artwork artwork) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(artwork.imageUrl, fit: BoxFit.cover),
            // 호버 효과를 위한 오버레이
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // 작품 상세 페이지로 이동
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        artwork.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        artwork.artist,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        NumberFormat.currency(
                          symbol: '₩',
                          locale: 'ko_KR',
                          decimalDigits: 0,
                        ).format(
                          artwork.currentBid > 0
                              ? artwork.currentBid
                              : artwork.startingPrice,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }

  Widget _buildArtistGrid() {
    // 아티스트 목록을 위한 데이터 (실제로는 별도 모델이 필요할 수 있음)
    final artists =
        _artworks
            .take(6)
            .map((artwork) => artwork.artist)
            .toSet()
            .take(3)
            .toList();

    // 화면 너비에 따라 그리드 열 수 조정
    int crossAxisCount = 3;
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artwork = _artworks.firstWhere(
            (a) => a.artist == artists[index],
          );
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(artwork.imageUrl, fit: BoxFit.cover),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // 아티스트 상세 페이지로 이동
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Center(
                        child: Text(
                          artwork.artist,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulletinBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공지사항', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 30),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                  title: Text(
                    '공지사항 제목 ${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '2023-05-${10 + index}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                  onTap: () {
                    // 공지사항 상세 페이지로 이동
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
