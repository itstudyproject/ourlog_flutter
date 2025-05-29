import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart'; // Sendbird SDK
import '../providers/auth_provider.dart'; // 사용자 JWT 토큰 접근용
import '../providers/chat_provider.dart'; // Sendbird 연동 및 채널 목록 접근용
// import '../models/user_profile.dart'; // UserProfile 모델 임포트 (필요 시)


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  @override
  void initState() {
    debugPrint('ChatListScreen initState called'); // initState 호출 확인용
    super.initState();
    // 위젯 초기화 시 Sendbird 연결 및 채널 목록 로드 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _initializeAndLoadChannels();
       // authProvider가 선언된 후 토큰 값을 확인하도록 위치 이동
       final authProvider = Provider.of<AuthProvider>(context, listen: false);
       debugPrint('JWT Token check in ChatListScreen: ${authProvider.token}');
    });
  }

  Future<void> _initializeAndLoadChannels() async {
    debugPrint('_initializeAndLoadChannels started');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final jwtToken = authProvider.token;
    final userId = authProvider.userId;

    if (jwtToken != null && jwtToken.isNotEmpty) {
      debugPrint('_initializeAndLoadChannels: JWT token found, fetching Sendbird auth info...');
      final authInfo = await chatProvider.fetchSendbirdAuthInfo(jwtToken, userId!);
      debugPrint('_initializeAndLoadChannels: fetchSendbirdAuthInfo result: $authInfo');

      if (authInfo != null && authInfo['userId'] != null && authInfo['accessToken'] != null) {
        debugPrint('_initializeAndLoadChannels: Sendbird auth info successful, initializing and connecting...');
        await chatProvider.initializeAndConnect(
          authInfo['userId'],
          authInfo['accessToken'],
          jwtToken,
        );
        debugPrint('_initializeAndLoadChannels: initializeAndConnect completed.');
      } else {
         debugPrint('Failed to get Sendbird auth info.');
      }
    } else {
       debugPrint('JWT token not found. Cannot initialize chat.');
       // 로그인 페이지로 이동 또는 에러 표시 로직 필요
    }
    debugPrint('_initializeAndLoadChannels finished');
  }


  @override
  Widget build(BuildContext context) {
    // listen: true를 사용하여 상태 변화 감지
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context); // JWT 토큰 전달 위해 필요 시 listen: false로 사용

    // 로딩 상태 표시
    if (chatProvider.isLoading || chatProvider.isChannelsLoading || !chatProvider.isSendbirdInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
         backgroundColor: Colors.black, // 로딩 화면 배경색
      );
    }

    // 에러 메시지 표시
    if (chatProvider.errorMessage != null || chatProvider.channelsErrorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              chatProvider.errorMessage ?? chatProvider.channelsErrorMessage ?? '알 수 없는 오류 발생',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
         backgroundColor: Colors.black87, // 에러 화면 배경색
      );
    }

    // 채널 목록 표시
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 목록'),
        backgroundColor: Colors.black, // 테마에 맞게 조정
         foregroundColor: Colors.white, // AppBar 아이콘/텍스트 색상
      ),
      body: chatProvider.channels.isEmpty
          ? const Center(child: Text('대화 채널이 없습니다.', style: TextStyle(color: Colors.white70))) // 채널이 없을 때 메시지
          : ListView.builder(
              itemCount: chatProvider.channels.length,
              itemBuilder: (context, index) {
                final channel = chatProvider.channels[index];
                // 1:1 채팅 상대방 정보 가져오기
                final otherUser = channel.memberCount == 2 && chatProvider.currentUser != null
                    ? channel.members.firstWhere(
                        (m) => m.userId != chatProvider.currentUser!.userId,
                        orElse: () => channel.members.first,
                      )
                    : null;

                // 상대방 프로필 정보 가져오기 (ChatProvider의 userProfiles 맵 활용)
                final partnerProfile = otherUser != null ? chatProvider.userProfiles[otherUser.userId] : null;

                // 채널 제목 결정 (1:1은 상대방 닉네임, 그룹은 채널 이름)
                final String channelTitle = partnerProfile?.nickname ?? otherUser?.nickname ?? channel.name ?? '그룹 채널';

                // 프로필 이미지 URL 결정
                final String? profileImageUrl = partnerProfile?.profileImageUrl;
                // TODO: '/images/mypage.png'와 같은 기본 이미지 처리가 필요할 수 있습니다.


                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueGrey, // 기본 배경색
                    // 프로필 이미지 표시 (URL이 있다면 NetworkImage, 없다면 기본 아이콘/이미지)
                    backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl == null && channelTitle.isNotEmpty
                        ? Text(channelTitle[0], style: const TextStyle(color: Colors.white)) // 첫 글자 표시
                        : (profileImageUrl == null ? const Icon(Icons.person, color: Colors.white) : null), // 기본 아이콘
                  ),
                  title: Text(channelTitle, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(channel.lastMessage?.message ?? '메시지 없음', style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    // 채널 선택 시 채팅 화면으로 이동
                    debugPrint('Selected channel: ${channel.name ?? channel.url}');
 // channel 객체가 null이 아닌지 확인
                    Navigator.pushNamed(
                      context,
                      '/chat', // 채팅 화면 라우트 이름
                      arguments: channel, // 선택된 GroupChannel 객체를 인자로 전달
                    );
                                    },
                );
              },
            ),
       backgroundColor: Colors.black87, // 화면 배경색
    );
  }
}

extension on GroupChannel {
  get url => null;
}

// ChatProvider에 setErrorMessage 메서드가 필요하다면 추가합니다.
/*
class ChatProvider with ChangeNotifier {
  // ... 기존 코드 ...
   void setErrorMessage(String message) {
     _errorMessage = message;
     notifyListeners();
   }
   void clearErrorMessage() {
     _errorMessage = null;
     notifyListeners();
   }
  // ... 나머지 코드 ...
}
*/
