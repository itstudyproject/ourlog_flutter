import 'package:flutter/material.dart';

const String appVersion = '1.0.0';

class AppinfoScreen extends StatelessWidget {
  const AppinfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainTextStyle = TextStyle(color: Colors.white, fontSize: 16, height: 1.5);
    final labelStyle = TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.bold);
    final subTextStyle = TextStyle(color: Colors.grey[300], fontSize: 14);
    final footerTextStyle = TextStyle(color: Colors.grey[500], fontSize: 12);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('앱 정보', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OurLog',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              '아티스트를 위한 최고의 커뮤니티!\n작품 공유와 피드백을 통해 창작 여정을 응원합니다.',
              style: mainTextStyle,
            ),

            const SizedBox(height: 32),
            Divider(color: Colors.grey[700]),
            const SizedBox(height: 16),

            // 📌 Contact Section Title
            Text(
              'Contact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),            const SizedBox(height: 12),
            Text('📧 Email: contact@ourlog.com', style: mainTextStyle),
            const SizedBox(height: 8),
            Text('📞 Tel: 0687-5640', style: mainTextStyle),

            const SizedBox(height: 32),
            Divider(color: Colors.grey[700]),
            const SizedBox(height: 12),

            Center(
              child: Text(
                'App Version $appVersion',
                style: subTextStyle,
              ),
            ),

            const Spacer(),
            Center(
              child: Text(
                '© 2025 OurLog. All rights reserved.',
                style: footerTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
