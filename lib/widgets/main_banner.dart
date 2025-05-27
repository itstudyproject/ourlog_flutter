import 'package:flutter/material.dart';

class MainBanner extends StatelessWidget {
  const MainBanner({super.key});

  @override
  Widget build(BuildContext context) {
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
}
