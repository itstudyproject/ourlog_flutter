import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  Widget _buildFooterLink(String text, BuildContext context) {
    String route = '';

    switch (text) {
      case '이용약관':
        route = '/customer/termscondition';
        break;
      case '개인정보처리방침':
        route = '/customer/privacypolicy';
        break;
      case '고객센터':
        route = '/customer/customercenter';
        break;
    }

    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }


  Widget _buildFooterLink(String text, BuildContext context) {
    String route = '';

    switch (text) {
      case '이용약관':
        route = '/customer/termscondition';
        break;
      case '개인정보처리방침':
        route = '/customer/privacypolicy';
        break;
      case '고객센터':
        route = '/customer/customercenter';
        break;
    }

    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로고 + 소개글
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // ✅ 로고와 글자 수직 가운데 정렬
            children: [
              Image.asset(
                'assets/images/Symbol.png',
                width: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OurLog',
                      style: TextStyle(
<<<<<<< HEAD
                        fontSize: 20,
=======
                        fontSize: 28,
>>>>>>> origin/dev/sin-tae
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
<<<<<<< HEAD
                    const SizedBox(height: 10),
                    Text(
                      '아티스트를 위한 최고의 커뮤니티!\n작품 공유와 피드백을 통해 창작 여정을\n응원합니다.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
=======
                    const SizedBox(height: 16),
                    Text(
                      '아티스트를 위한 최고의 커뮤니티!\n작품 공유와 피드백을 통해 창작 여정을 응원합니다.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
>>>>>>> origin/dev/sin-tae
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 고객지원 링크 한 줄
          Wrap(
            spacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Support',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildFooterLink('이용약관', context),
              _buildFooterLink('개인정보처리방침', context),
              _buildFooterLink('고객센터', context),
            ],
          ),

          const SizedBox(height: 10),

          // Contact 영역 (Email과 Tel 정렬)

          // Contact 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
<<<<<<< HEAD
              const SizedBox(width: 10),
=======
              const SizedBox(width: 12),
>>>>>>> origin/dev/sin-tae
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📧 Email: contact@ourlog.com',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📞 Tel: 0687-5640',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

<<<<<<< HEAD
          const SizedBox(height: 15),
=======
          const SizedBox(height: 20),
>>>>>>> origin/dev/sin-tae

          // SNS 아이콘 가운데 정렬
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSocialIcon(Icons.facebook),
                _buildSocialIcon(Icons.camera_alt),
                _buildSocialIcon(Icons.chat),
              ],
            ),
          ),

<<<<<<< HEAD
          const SizedBox(height: 5),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 5),
=======
          const SizedBox(height: 10),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 10),
>>>>>>> origin/dev/sin-tae
          Center(
            child: Text(
              '© ${DateTime.now().year} OurLog. All rights reserved.',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildSocialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        onTap: () {
          // SNS 링크로 이동
        },
        child: Icon(
          icon,
          color: Colors.grey[400],
          size: 22,
        ),
      ),
    );
  }
}