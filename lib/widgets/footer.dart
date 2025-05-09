import 'package:flutter/material.dart';
import '../constants/theme.dart';

class Footer extends StatelessWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        children: [
          // 로고 및 소개
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 로고
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OurLog',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '아티스트와 컬렉터를 위한 경매 플랫폼',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 링크 섹션 1
              Expanded(
                flex: 1,
                child: _buildLinkSection('서비스 안내', [
                  '서비스 소개',
                  '이용 가이드',
                  '자주 묻는 질문',
                  '공지사항',
                ]),
              ),
              
              // 링크 섹션 2
              Expanded(
                flex: 1,
                child: _buildLinkSection('정책', [
                  '이용약관',
                  '개인정보처리방침',
                  '저작권 정책',
                  '경매 규정',
                ]),
              ),
              
              // 링크 섹션 3
              Expanded(
                flex: 1,
                child: _buildLinkSection('고객지원', [
                  '고객센터',
                  '문의하기',
                  '피드백',
                  '제휴 문의',
                ]),
              ),
            ],
          ),
          
          const SizedBox(height: 50),
          
          // 저작권 정보
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '© ${DateTime.now().year} OurLog. All rights reserved.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    
                    // 소셜 미디어 아이콘
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook),
                        _buildSocialIcon(Icons.photo_camera),
                        _buildSocialIcon(Icons.chat),
                        _buildSocialIcon(Icons.video_library),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '사업자등록번호: 123-45-67890 | 대표: 홍길동 | 주소: 서울특별시 강남구 테헤란로 123',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

  Widget _buildLinkSection(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              // 해당 링크로 이동
            },
            child: Text(
              link,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: GestureDetector(
        onTap: () {
          // 소셜 미디어 페이지로 이동
        },
        child: Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }
} 