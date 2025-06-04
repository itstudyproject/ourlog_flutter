import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart'; // Sendbird SDK
// Sendbird SDK의 Channel 관련 추가 임포트 (필요하다면)
// import 'package:sendbird_chat_sdk/features/group_channel/group_channel.dart'; // 예시: 특정 기능이 분리된 경우
// import 'package:sendbird_chat_sdk/core/models/enums.dart'; // 예시: enum이 분리된 경우
// Sendbird SDK의 GroupChannel 확장 메서드를 위한 임포트 (추정 경로)

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
      debugPrint(
        '_initializeAndLoadChannels: JWT token found, fetching Sendbird auth info...',
      );
      final authInfo = await chatProvider.fetchSendbirdAuthInfo(
        jwtToken,
        userId!,
      );
      debugPrint(
        '_initializeAndLoadChannels: fetchSendbirdAuthInfo result: $authInfo',
      );

      if (authInfo != null &&
          authInfo['userId'] != null &&
          authInfo['accessToken'] != null) {
        debugPrint(
          '_initializeAndLoadChannels: Sendbird auth info successful, initializing and connecting...',
        );
        await chatProvider.initializeAndConnect(
          authInfo['userId'],
          authInfo['accessToken'],
          jwtToken,
        );
        debugPrint(
          '_initializeAndLoadChannels: initializeAndConnect completed.',
        );
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
    final authProvider = Provider.of<AuthProvider>(
      context,
    ); // JWT 토큰 전달 위해 필요 시 listen: false로 사용

    // 로딩 상태 표시
    if (chatProvider.isLoading ||
        chatProvider.isChannelsLoading ||
        !chatProvider.isSendbirdInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        backgroundColor: Colors.black, // 로딩 화면 배경색
      );
    }

    // 에러 메시지 표시
    if (chatProvider.errorMessage != null ||
        chatProvider.channelsErrorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              chatProvider.errorMessage ??
                  chatProvider.channelsErrorMessage ??
                  '알 수 없는 오류 발생',
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
                      height:
                          MediaQuery.of(context).size.height * 0.8, // 모달 높이 설정
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
                              child:
                                  _searchResults.isEmpty
                                      ? const Text(
                                        '검색 결과 없음', // 검색 결과가 없을 때
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                        ),
                                      )
                                      : ListView.builder(
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          final user = _searchResults[index];
                                          return ListTile(
                                            title: Text(
                                              user.nickname ?? user.userId,
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            subtitle: Text(
                                              user.userId,
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                            // TODO: 사용자 선택 시 1:1 채팅 개설 로직 연결
                                            onTap: () {
                                              debugPrint(
                                                'User selected: ${user.userId}',
                                              );
                                              _createAndNavigateToChannel(
                                                user.userId,
                                              );
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
      body:
          chatProvider.channels.isEmpty
              ? const Center(
                child: Text(
                  '대화 채널이 없습니다.',
                  style: TextStyle(color: Colors.white70),
                ),
              ) // 채널이 없을 때 메시지
              : ListView.builder(
                itemCount: chatProvider.channels.length,
                itemBuilder: (context, index) {
                  final channel = chatProvider.channels[index];
                  // 1:1 채팅 상대방 정보 가져오기
                  final otherUser =
                      channel.memberCount == 2 &&
                              chatProvider.currentUser != null
                          ? channel.members.firstWhere(
                            (m) => m.userId != chatProvider.currentUser!.userId,
                            orElse: () => channel.members.first,
                          )
                          : null;

                  // 상대방 프로필 정보 가져오기 (ChatProvider의 userProfiles 맵 활용)
                  final partnerProfile =
                      otherUser != null
                          ? chatProvider.userProfiles[otherUser.userId]
                          : null;

                  // 채널 제목 결정 (1:1은 상대방 닉네임, 그룹은 채널 이름)
                  final String channelTitle =
                      partnerProfile?.nickname ??
                      otherUser?.nickname ??
                      channel.name ??
                      '그룹 채널';

                  // 프로필 이미지 URL 결정
                  final String? profileImageUrl =
                      partnerProfile?.profileImageUrl;
                  // TODO: '/images/mypage.png'와 같은 기본 이미지 처리가 필요할 수 있습니다.

                  return ListTile(
                    onLongPress:
                        () => _showChannelOptionsMenu(context, channel),
                    // 길게 눌렀을 때 메뉴 표시 함수 호출
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey, // 기본 배경색
                      // 프로필 이미지 표시 (URL이 있다면 NetworkImage, 없다면 기본 아이콘/이미지)
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                      child:
                          profileImageUrl == null && channelTitle.isNotEmpty
                              ? Text(
                                channelTitle[0],
                                style: const TextStyle(color: Colors.white),
                              ) // 첫 글자 표시
                              : (profileImageUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  )
                                  : null), // 기본 아이콘
                    ),
                    title: Text(
                      channelTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      channel.lastMessage?.message ?? '메시지 없음',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      // 채널 선택 시 채팅 화면으로 이동
                      debugPrint(
                        'Selected channel: ${channel.name ?? channel.channelUrl}',
                      );
                      if (channel != null) {
                        // channel 객체가 null이 아닌지 확인
                        Navigator.pushNamed(
                          context,
                          '/chat', // 채팅 화면 라우트 이름
                          arguments: channel, // 선택된 GroupChannel 객체를 인자로 전달
                        );
                      } else {
                        // channel이 null일 경우 오류 처리 또는 사용자에게 알림
                        debugPrint(
                          'Attempted to navigate to chat with null channel.',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('채널 정보를 불러오는데 실패했습니다. 다시 시도해주세요.'),
                          ),
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
    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    ); // AuthProvider 인스턴스 가져오기

    final jwtToken = authProvider.token; // JWT 토큰 가져오기
    final currentUserId = authProvider.userId; // 현재 사용자 ID 가져오기

    // 토큰 또는 사용자 ID가 없는 경우 오류 처리
    if (jwtToken == null || currentUserId == null) {
      debugPrint(
        'JWT token or current user ID is null. Cannot create channel.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 인증 정보를 불러올 수 없습니다. 다시 로그인해주세요.')),
      );
      // TODO: 필요하다면 로그인 페이지로 이동
      return;
    }

    final channel = await chatProvider.create1to1Channel(
      targetUserId,
      jwtToken,
      currentUserId,
    );

    if (channel != null) {
      // 채널 개설 또는 찾기 성공 시 채팅 화면으로 이동
      Navigator.pushNamed(
        context,
        '/chat', // 채팅 화면 라우트 이름
        arguments: channel, // 생성/찾은 GroupChannel 객체 전달
      );
    } else {
      // 채널 개설 실패 시 사용자에게 알림
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1:1 채팅 채널 개설에 실패했습니다.')));
    }
  }

  // 채널 옵션 메뉴 표시 함수
  void _showChannelOptionsMenu(BuildContext context, GroupChannel channel) {
    showModalBottomSheet(
      // 모달 바텀 시트 표시
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.white), // 아이콘 색상 흰색으로
                tileColor: const Color(0xFF2A2A2A), // 배경색 진한 회색으로 변경
                title: Text('채팅방 나가기', style: TextStyle(color: Colors.white)), // 글자색 흰색으로
                onTap: () {
                  Navigator.pop(context); // 모달 닫기
                  _leaveChannel(channel); // 나가기 로직 호출
                },
              ),
              ListTile(
                leading: Icon(
                  channel.myMutedState == MuteState.unmuted
                      ? Icons.notifications_off
                      : Icons.notifications_active,
                  color: Colors.white, // 아이콘 색상 흰색으로
                ), // 알림 아이콘 (현재 상태에 따라 변경)
                tileColor: const Color(0xFF2A2A2A), // 배경색 진한 회색으로 변경
                title: Text(channel.myMutedState == MuteState.unmuted ? '알림 끄기' : '알림 켜기', style: TextStyle(color: Colors.white)), // 텍스트도 상태에 따라 변경, 글자색 흰색으로
                onTap: () {
                  Navigator.pop(context); // 모달 닫기
                  _toggleNotification(channel); // 알림 토글 로직 호출
                },
              ),
              // 이름 변경 기능은 1:1 채널에는 제한적이거나 적용 방식이 다를 수 있음
              ListTile(
                leading: Icon(Icons.edit, color: Colors.white), // 아이콘 색상 흰색으로
                tileColor: const Color(0xFF2A2A2A), // 배경색 진한 회색으로 변경
                title: Text('이름 변경', style: TextStyle(color: Colors.white)), // 글자색 흰색으로
                onTap: () {
                  Navigator.pop(context); // 모달 닫기
                  // TODO: 이름 변경 로직 구현 (그룹 채널에 주로 해당)
                  debugPrint('채널 이름 변경 시도: ${channel.channelUrl}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('이름 변경 기능은 그룹 채널에 해당하거나 현재 지원되지 않습니다.'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 채널 나가기 로직
  Future<void> _leaveChannel(GroupChannel channel) async {
    try {
      await channel.leave();
      // 채널 목록에서 제거 또는 업데이트
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchMyGroupChannels(
        Provider.of<AuthProvider>(context, listen: false).token!,
      ); // 채널 목록 새로고침
      debugPrint('채널 나가기 성공: ${channel.channelUrl}');
    } catch (e) {
      debugPrint('채널 나가기 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채널 나가기 실패: ${e.toString()}')), // 실패 메시지 표시
      );
    }
  }

  // 알림 토글 로직
  Future<void> _toggleNotification(GroupChannel channel) async {
    try {
      // 현재 알림 상태 확인 (myPushTriggerOption 사용)
      final bool isCurrentlyMuted =
          channel.myPushTriggerOption == GroupChannelPushTriggerOption.off;

      if (!isCurrentlyMuted) {
        // 현재 알림 켜져 있으면 끄기
        await channel.setMyPushTriggerOption(
          GroupChannelPushTriggerOption.off,
        ); // 알림 끄기
        debugPrint('채널 알림 끄기 성공: ${channel.channelUrl}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채널 알림을 껐습니다.')), // 성공 메시지 표시
        );
      } else {
        // 현재 알림 꺼져 있으면 켜기
        await channel.setMyPushTriggerOption(
          GroupChannelPushTriggerOption.all,
        ); // 알림 켜기 (모든 메시지 알림)
        debugPrint('채널 알림 켜기 성공: ${channel.channelUrl}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채널 알림을 켰습니다.')), // 성공 메시지 표시
        );
      }
      // UI 업데이트를 위해 채널 목록 새로고침 또는 개별 채널 업데이트 필요 (myPushTriggerOption 상태 반영)
      // ChatProvider의 onChannelUpdated 핸들러가 작동하면 자동으로 업데이트될 수도 있음
      // 여기서는 명시적으로 채널 목록을 다시 가져오도록 합니다.
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchMyGroupChannels(
        Provider.of<AuthProvider>(context, listen: false).token!,
      ); // 채널 목록 새로고침
    } catch (e) {
      debugPrint('알림 설정 변경 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알림 설정 변경 실패: ${e.toString()}')), // 실패 메시지 표시
      );
    }
  }
}
