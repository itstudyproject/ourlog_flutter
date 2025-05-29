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

  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = []; // 검색 결과를 저장할 목록

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // TODO: 사용자 검색 로직 구현
  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    // ChatProvider의 searchUsersByNickname 메서드 호출
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // 예시:
    try {
      final users = await chatProvider.searchUsersByNickname(query);
      setState(() {
        _searchResults = users;
      });
    } catch (e) {
      debugPrint('User search failed: $e');
      // 에러 처리: 사용자에게 알림 등
      setState(() {
        _searchResults = []; // 에러 시 결과 초기화
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add), // 새 채팅 시작 아이콘
            onPressed: () {
              // TODO: 사용자 검색 화면으로 이동하거나 다이얼로그를 표시하여 1:1 채팅 개설 로직 시작
              debugPrint('새 채팅 시작 버튼 눌림');
              // 예시: Navigator.pushNamed(context, '/userSearch');
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // 키보드가 올라올 때 모달 크기 조정
                builder: (BuildContext context) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.8, // 모달 높이 설정
                      color: Colors.white, // 모달 배경색 (필요에 따라 조정)
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _searchUsers, // 검색어 변경 시 검색 실행
                              decoration: InputDecoration(
                                hintText: '닉네임 또는 사용자 ID 검색',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              // 검색 결과 목록 표시
                              child: _searchResults.isEmpty
                                  ? const Text(
                                      '검색 결과 없음', // 검색 결과가 없을 때
                                      style: TextStyle(color: Colors.black54, fontSize: 16),
                                    )
                                  : ListView.builder(
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final user = _searchResults[index];
                                        return ListTile(
                                          title: Text(user.nickname ?? user.userId, style: TextStyle(color: Colors.black)),
                                          subtitle: Text(user.userId, style: TextStyle(color: Colors.black54)),
                                          // TODO: 사용자 선택 시 1:1 채팅 개설 로직 연결
                                          onTap: () {
                                            debugPrint('User selected: ${user.userId}');
                                            _createAndNavigateToChannel(user.userId);
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
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
                    debugPrint('Selected channel: ${channel.name ?? channel.channelUrl}');
                    if (channel != null) { // channel 객체가 null이 아닌지 확인
                      Navigator.pushNamed(
                        context,
                        '/chat', // 채팅 화면 라우트 이름
                        arguments: channel, // 선택된 GroupChannel 객체를 인자로 전달
                      );
                    } else {
                      // channel이 null일 경우 오류 처리 또는 사용자에게 알림
                      debugPrint('Attempted to navigate to chat with null channel.');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('채널 정보를 불러오는데 실패했습니다. 다시 시도해주세요.')),
                      );
                    }
                  },
                );
              },
            ),
       backgroundColor: Colors.black87, // 화면 배경색
    );
  }

  // 사용자 선택 후 1:1 채널 개설 및 채팅 화면으로 이동
  void _createAndNavigateToChannel(String targetUserId) async {
    Navigator.pop(context); // 모달 닫기

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final channel = await chatProvider.create1to1Channel(targetUserId);

    if (channel != null) {
      // 채널 개설 또는 찾기 성공 시 채팅 화면으로 이동
      Navigator.pushNamed(
        context,
        '/chat', // 채팅 화면 라우트 이름
        arguments: channel, // 생성/찾은 GroupChannel 객체 전달
      );
    } else {
      // 채널 개설 실패 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1:1 채팅 채널 개설에 실패했습니다.')),
      );
    }
  }
}
