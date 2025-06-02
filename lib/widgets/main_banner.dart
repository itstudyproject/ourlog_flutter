import 'dart:async';
import 'package:flutter/material.dart';

class MainBanner extends StatefulWidget {
  const MainBanner({super.key});

  @override
  State<MainBanner> createState() => _MainBannerState();
}

class _MainBannerState extends State<MainBanner> {
  final List<String> images = [
    'assets/images/sun.png',
    'assets/images/bada.png',
    'assets/images/star.png',
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startImageTimer();
  }

  void _startImageTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 전체 배너 높이를 가로길이의 1/2 비율로 잡음
    final bannerHeight = MediaQuery.of(context).size.width / 0.9;

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Center(
              key: ValueKey(_currentIndex), // 애니메이션 전환 키
              child: ClipRect(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: bannerHeight,
                  child: Image.asset(
                    images[_currentIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 120,
            bottom: 25,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'OurLog',
                    style: TextStyle(
                      fontSize: 45,
                      fontFamily: 'NanumSquareNeo',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '당신의 이야기가 작품이 되는 곳',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'NanumSquareNeo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '아티스트와 컬렉터가 만나는 특별한 공간',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'NanumSquareNeo',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
