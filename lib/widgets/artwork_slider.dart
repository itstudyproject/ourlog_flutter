import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/artwork.dart'; // Artwork 모델 위치에 따라 조정

class ArtworkSlider extends StatefulWidget {
  final List<Artwork> artwork;

  const ArtworkSlider({super.key, required this.artwork});

  @override
  State<ArtworkSlider> createState() => _ArtworkSliderState();
}

class _ArtworkSliderState extends State<ArtworkSlider> {
  late PageController _pageController;
  late PageController _artistPageController;
  int _currentSlideIndex = 0;
  int _currentArtistSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _artistPageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _artistPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artwork.isEmpty) return const SizedBox();

    final popularArtworks = widget.artwork.take(3).toList();

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
                  color: _currentSlideIndex == index ? Colors.blue : Colors.grey[700],
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
                  // 작품 상세 페이지 이동 로직
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
    final artists = widget.artwork.map((a) => a.artist).toSet().take(3).toList();
    final artistArtworks = artists.map((artist) => widget.artwork.firstWhere((a) => a.artist == artist)).toList();

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
                            // 아티스트 상세 페이지 이동 로직
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
                color: _currentArtistSlideIndex == index ? Colors.blue : Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
