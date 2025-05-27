import 'package:flutter/material.dart';
import 'package:ourlog/widgets/bulletin_board.dart';
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
  int _currentArtistSlideIndex = 0;
  final PageController _pageController = PageController();
  final PageController _artistPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadArtworks();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _artistPageController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (!mounted) return;

    setState(() {
      _currentSlideIndex =
          (_currentSlideIndex + 1) % (_artworks.length > 3 ? 3 : _artworks.length);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  void _loadArtworks() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _artworks = ArtworkService.getArtworks();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Header(key: Key('header')),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadArtworks();
                    },
                    color: AppTheme.primaryColor,
                    backgroundColor: Colors.black,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMainBanner(),
                          _buildArtworkSlider(),
                          const BulletinBoard(),
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbanner1.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned(
            left: 120,
            bottom: 40,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 18, fontFamily: 'NanumSquareNeo'),
                      children: [TextSpan(text: 'OurLog')],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '당신의 이야기가 작품이 되는 곳',
                    style: TextStyle(fontSize: 9, fontFamily: 'NanumSquareNeo'),
                  ),
                  const SizedBox(height: 2),
                  const Text(
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

    final popularArtworks = _artworks.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text('인기 작품 추천', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(
            '사람들의 마음을 사로잡은 그림들을 소개합니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
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
                  color: _currentSlideIndex == index ? AppTheme.primaryColor : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text('주요 아티스트', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(
            '트렌드를 선도하는 아티스트들을 소개합니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          _buildArtistSlider(),
        ],
      ),
    );
  }

  Widget _buildArtworkSlide(Artwork artwork) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 5)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(artwork.imageUrl, fit: BoxFit.cover),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // 작품 상세 페이지 이동
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(artwork.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(artwork.artist, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(
                        NumberFormat.currency(symbol: '₩', locale: 'ko_KR', decimalDigits: 0).format(
                          artwork.currentBid > 0 ? artwork.currentBid : artwork.startingPrice,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildArtistSlider() {
    final artists = _artworks.map((a) => a.artist).toSet().take(3).toList();
    final artistArtworks = artists.map((artist) => _artworks.firstWhere((a) => a.artist == artist)).toList();

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _artistPageController,
            itemCount: artistArtworks.length,
            onPageChanged: (index) {
              setState(() {
                _currentArtistSlideIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final artwork = artistArtworks[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(artwork.imageUrl, fit: BoxFit.cover),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // 아티스트 상세 페이지 이동
                          },
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Text(
                                artwork.artist,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            artistArtworks.length,
                (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentArtistSlideIndex == index ? AppTheme.primaryColor : Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
