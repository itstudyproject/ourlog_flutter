import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
// import 'package:intl/intl.dart'; // 메시지 시간 표시 시 필요

class ChatScreen extends StatefulWidget {
  final GroupChannel channel;

  const ChatScreen({super.key, required this.channel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController(); // 메시지 입력 컨트롤러
  // 스크롤 컨트롤러 추가 (메시지 목록 하단으로 자동 스크롤)
  final ScrollController _scrollController = ScrollController();

  // 메시지 목록의 이전 길이를 추적하여 변화 감지
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 메시지 로드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _loadMessages();
    });
  }

  // React CSS의 색상 변수들을 Flutter Color로 매핑 (근사치)
  Color get _bgMain => Colors.black;
  Color get _bgSecondary => const Color(0xFF222222);
  Color get _borderColor => const Color(0xFF444444);
  Color get _textColor => Colors.white;
  Color get _textSub => Colors.grey[300]!; // 연한 회색
  Color get _highlight => const Color(0xFFf8c147); // 주황색 계열

  // 메시지 로드 메서드 호출
  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadMessages(widget.channel);
     // 메시지 로드 후 최하단으로 스크롤
    _scrollToBottom();
  }

  // 메시지 전송 메서드
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return; // 공백만 있는 경우 전송 안 함

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
     // Sendbird SDK를 사용하여 메시지 전송 로직 구현
     try {
       // UserMessageCreateParams를 사용하여 메시지 생성
       final params = UserMessageCreateParams(message: _messageController.text.trim());
       // Sendbird SDK를 통해 메시지 전송
       final sentMessage = widget.channel.sendUserMessage(params);
       debugPrint('Message sent: ${sentMessage.message}');

       // TODO: 전송된 메시지를 로컬 메시지 목록에 즉시 추가하여 UI 업데이트
       // Sendbird MessageCollection 핸들러에서 onMessagesAdded를 통해 자동으로 추가될 수도 있지만,
       // 즉각적인 UI 반응을 위해 여기에서 먼저 추가할 수 있습니다.
       // chatProvider.addMessageToCurrentChannel(sentMessage); // ChatProvider에 이 메서드 필요

     } catch (e) {
       debugPrint('Failed to send message: $e');
       // 메시지 전송 실패 시 에러 처리 (예: SnackBar 표시)
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('메시지 전송 실패: ${e.toString()}')),
        );
     }

    _messageController.clear();
    // 메시지 전송 후 목록 하단으로 스크롤
    _scrollToBottom();
  }

   // 메시지 목록 최하단으로 스크롤
   void _scrollToBottom() {
     // 메시지 목록이 빌드된 후 스크롤 가능하도록 작은 딜레이를 줍니다.
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_scrollController.hasClients) {
         _scrollController.animateTo(
           _scrollController.position.maxScrollExtent, // 목록의 끝으로 스크롤
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeOut,
         );
       }
     });
   }


  @override
  void dispose() {
    // 위젯 dispose 시 컨트롤러 정리
    _messageController.dispose();
    _scrollController.dispose();

    // MessageCollection 관리는 ChatProvider에서 하므로 여기서는 정리하지 않습니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // listen: true를 사용하여 메시지 목록 변화 감지
    final chatProvider = Provider.of<ChatProvider>(context);

    // AuthProvider에서 현재 사용자의 토큰을 가져옵니다.
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // listen: false 가능
    final userToken = authProvider.token; // AuthProvider에 token 속성이 있다고 가정합니다.

    // 메시지 목록의 길이가 변경될 때 (새 메시지 도착 시) 스크롤
    if (chatProvider.currentChannelMessages.length != _previousMessageCount) {
      _previousMessageCount = chatProvider.currentChannelMessages.length;
      // 새 메시지가 로드되거나 추가된 후 다음 프레임에서 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // 로딩 상태 표시
    if (chatProvider.isMessagesLoading && chatProvider.currentChannelMessages.isEmpty) {
       return Scaffold(
          appBar: AppBar(
            title: Text(widget.channel.name ?? '채팅'),
            backgroundColor: _bgMain,
            foregroundColor: Colors.white,
          ),
          body: const Center(child: CircularProgressIndicator()),
          backgroundColor: _bgSecondary,
       );
    }

    // 에러 메시지 표시
    if (chatProvider.messagesErrorMessage != null) {
       return Scaffold(
          appBar: AppBar(
             title: Text(widget.channel.name ?? '채팅'),
             backgroundColor: _bgMain,
             foregroundColor: Colors.white,
          ),
          body: Center(
             child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                   chatProvider.messagesErrorMessage!,
                   textAlign: TextAlign.center,
                   style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
             ),
          ),
          backgroundColor: _bgSecondary,
       );
    }


    // 채팅 화면 UI
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name ?? '채팅'),
         backgroundColor: _bgMain,
         foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 스크롤 컨트롤러 연결
              reverse: false, // 가장 오래된 메시지가 위로, 최신 메시지가 아래로 가도록 설정
              itemCount: chatProvider.currentChannelMessages.length,
              itemBuilder: (context, index) {
                // 메시지 목록은 reverse: false 상태이므로, 인덱스 순서대로 가져옵니다.
                final message = chatProvider.currentChannelMessages[index];

                // React 스타일: 메시지 행
                final isMyMessage = message.sender?.userId == chatProvider.currentUser?.userId;

                // TODO: 메시지 타입에 따른 다른 위젯 표시 (UserMessage, FileMessage 등)
                // 현재는 UserMessage만 간단히 표시
                if (message is UserMessage) {
                   // React 스타일: 메시지 정렬
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // React CSS의 margin-bottom: 10px 근사
                     child: Row(
                       mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.end, // 아바타와 메시지 하단 정렬
                       children: [
                         // 상대방 메시지일 경우에만 아바타 표시
                         if (!isMyMessage)
                           CircleAvatar(
                             radius: 16, // React CSS의 .profile-icon 크기 근사
                             backgroundColor: Colors.grey[400], // 기본 배경색
                              // 사용자 프로필 이미지 표시
                             backgroundImage: chatProvider.userProfiles[message.sender?.userId]?.profileImageUrl != null
                                ? NetworkImage(
                                    'http://10.100.204.144:8080' + chatProvider.userProfiles[message.sender?.userId]!.profileImageUrl!,
                                    // 인증 헤더 추가
                                    headers: userToken != null ? {'Authorization': 'Bearer $userToken'} : null,
                                  ) as ImageProvider
                                : null,
                             child: chatProvider.userProfiles[message.sender?.userId]?.profileImageUrl == null && message.sender?.nickname != null
                                 ? Text(message.sender!.nickname[0], style: TextStyle(color: Colors.black)) // 첫 글자 표시
                                 : null,
                           ),
                           SizedBox(width: !isMyMessage ? 8 : 0), // 아바타와 메시지 간격

                         // 메시지 내용 및 시간 (내 메시지/상대방 메시지)
                         // 상대방 메시지일 경우 닉네임 + 버블 + 시간
                         // 내 메시지일 경우 시간 + 버블
                         Expanded(
                           child: Column(
                             crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start, // 내 메시지는 우측, 상대방 메시지는 좌측 정렬
                             children: [
                               // 상대방 닉네임 (1:1 채팅에서 상대방 메시지일 경우에만 표시) - 메시지 버블 위로 이동
                                if (!isMyMessage && widget.channel.memberCount == 2)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4.0), // 닉네임과 버블 사이 간격
                                    child: Text(
                                      chatProvider.userProfiles[message.sender?.userId]?.nickname ?? message.sender?.nickname ?? '알 수 없는 사용자',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _textSub, // React text-sub 색상 사용
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                 // 메시지 버블과 시간 (가로 배치)
                                 Row(
                                  mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start, // 내 메시지는 우측, 상대방 메시지는 좌측 정렬
                                  crossAxisAlignment: CrossAxisAlignment.end, // 시간과 버블 하단 정렬
                                  children: [
                                    // 내 메시지일 경우 시간 먼저 표시
                                     if (isMyMessage)
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4.0), // 메시지 버블과의 간격
                                          child: Text(
                                            '${DateTime.fromMillisecondsSinceEpoch(message.createdAt).hour}:${DateTime.fromMillisecondsSinceEpoch(message.createdAt).minute.toString().padLeft(2, '0')}', // 간단한 시간 포맷
                                            style: TextStyle(fontSize: 10, color: _textSub), // React text-sub 색상
                                          ),
                                        ),

                                    // 메시지 버블
                                    Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                       margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Row의 padding으로 마진 대체
                                        decoration: BoxDecoration(
                                          color: isMyMessage
                                            ? _highlight // 내 메시지 색상 (React highlight)
                                            : _bgSecondary, // 상대방 메시지 색상 (React bg-secondary)
                                          borderRadius: BorderRadius.only(
                                           topLeft: Radius.circular(12), // 좌상단
                                           topRight: Radius.circular(12), // 우상단
                                           bottomLeft: Radius.circular(
                                               isMyMessage ? 12 : 2), // 좌하단 (내 메시지는 12, 상대방 메시지는 2)
                                           bottomRight: Radius.circular(
                                               isMyMessage ? 2 : 12), // 우하단 (내 메시지는 2, 상대방 메시지는 12)
                                         ),
                                      ),
                                      // TODO: 메시지 내 닉네임 표시 제거
                                      // if (!isMyMessage && widget.channel.memberCount == 2) Text(...)
                                      child: Text(
                                        message.message,
                                        style: TextStyle(color: isMyMessage ? Colors.black : _textColor), // 내 메시지는 검정, 상대방은 흰색
                                      ),
                                   ),

                                  // 상대방 메시지일 경우 시간 나중에 표시
                                   if (!isMyMessage)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4.0), // 메시지 버블과의 간격
                                        child: Text(
                                          '${DateTime.fromMillisecondsSinceEpoch(message.createdAt).hour}:${DateTime.fromMillisecondsSinceEpoch(message.createdAt).minute.toString().padLeft(2, '0')}', // 간단한 시간 포맷
                                          style: TextStyle(fontSize: 10, color: _textSub), // React text-sub 색상
                                         ),
                                      ),
                                  ],
                                 ),
                               ],
                             ),
                           ),
                       ],
                     ),
                   );
                } else if (message is FileMessage) {
                   // TODO: 파일 메시지 표시
                   final isMyMessage = message.sender?.userId == chatProvider.currentUser?.userId;
                   return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                         mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           // 상대방 메시지일 경우에만 아바타 표시
                            if (!isMyMessage)
                             CircleAvatar(
                               radius: 16,
                               backgroundColor: Colors.grey[400],
                                backgroundImage: chatProvider.userProfiles[message.sender?.userId]?.profileImageUrl != null
                                   ? NetworkImage(
                                       'http://10.100.204.144:8080' + chatProvider.userProfiles[message.sender?.userId]!.profileImageUrl!,
                                       // 인증 헤더 추가
                                       headers: userToken != null ? {'Authorization': 'Bearer $userToken'} : null,
                                    ) as ImageProvider
                                   : null,
                                child: chatProvider.userProfiles[message.sender?.userId]?.profileImageUrl == null && message.sender?.nickname != null
                                    ? Text(message.sender!.nickname[0], style: TextStyle(color: Colors.black)) // 첫 글자 표시
                                    : null,
                              ),
                               SizedBox(width: !isMyMessage ? 8 : 0), // 아바타와 메시지 간격

                           // 메시지 내용 및 시간 (내 메시지/상대방 메시지)
                           // 상대방 메시지일 경우 닉네임 + 버블 + 시간
                           // 내 메시지일 경우 시간 + 버블
                           Expanded(
                             child: Column(
                               crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start, // 내 메시지는 우측, 상대방 메시지는 좌측 정렬
                               mainAxisSize: MainAxisSize.min, // 컬럼 크기를 내용에 맞게
                               children: [
                                 // 상대방 닉네임 (1:1 채팅에서 상대방 메시지일 경우에만 표시) - 메시지 버블 위로 이동
                                  if (!isMyMessage && widget.channel.memberCount == 2)
                                    Padding(
                                     padding: EdgeInsets.only(bottom: 4.0), // 닉네임과 버블 사이 간격
                                      child: Text(
                                       chatProvider.userProfiles[message.sender?.userId]?.nickname ?? message.sender?.nickname ?? '알 수 없는 사용자',
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: _textSub, // React text-sub 색상 사용
                                         fontWeight: FontWeight.bold,
                                       ),
                                      ),
                                    ),

                                  // 파일 메시지 버블과 시간 (가로 배치)
                                  Row(
                                    mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start, // 내 메시지는 우측, 상대방 메시지는 좌측 정렬
                                    crossAxisAlignment: CrossAxisAlignment.end, // 시간과 버블 하단 정렬
                                    children: [
                                       // 내 메시지일 경우 시간 먼저 표시
                                      if (isMyMessage)
                                         Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4.0), // 메시지 버블과의 간격
                                            child: Text(
                                               '${DateTime.fromMillisecondsSinceEpoch(message.createdAt).hour}:${DateTime.fromMillisecondsSinceEpoch(message.createdAt).minute.toString().padLeft(2, '0')}',
                                               style: TextStyle(fontSize: 10, color: _textSub),
                                            ),
                                         ),

                                      // 파일 메시지 버블
                                    //   Container(
                                    //    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    //    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Row의 padding으로 마진 대체
                                    //     decoration: BoxDecoration(
                                    //        color: isMyMessage
                                    //         ? Colors.blue[200] // 내 파일 메시지 색상 (React 스타일 색상 매핑 필요)
                                    //         : Colors.orange[200], // 상대방 파일 메시지 색상 (React 스타일 색상 매핑 필요)
                                    //     borderRadius: BorderRadius.circular(8), // TODO: React 스타일 둥근 모서리 적용 필요
                                    //   ),
                                    //    child: Row(
                                    //      mainAxisSize: MainAxisSize.min,
                                    //      children: [
                                    //          Icon(Icons.insert_drive_drive_file, size: 18, color: Colors.black87), // TODO: React 스타일 색상 적용 필요
                                    //          SizedBox(width: 4),
                                    //          Flexible(
                                    //             child: Text(
                                    //               message.name ?? '파일', // message.name이 null인 경우 '파일'로 표시
                                    //               style: const TextStyle(color: Colors.black87), // TODO: React 스타일 색상 적용 필요
                                    //                overflow: TextOverflow.ellipsis,
                                    //             ),
                                    //          ),
                                    //      ],
                                    //   )
                                    // ),
                                   // 상대방 메시지일 경우 시간 나중에 표시
                                   if (!isMyMessage)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4.0), // 메시지 버블과의 간격
                                        child: Text(
                                          '${DateTime.fromMillisecondsSinceEpoch(message.createdAt).hour}:${DateTime.fromMillisecondsSinceEpoch(message.createdAt).minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(fontSize: 10, color: _textSub),
                                        ),
                                      ),
                                   ],
                                  ),
                                 // TODO: 파일 메시지 내 닉네임 표시 제거
                                 // if (!isMyMessage && widget.channel.memberCount == 2) Text(...)
                               ],
                             ),
                           ),
                       ],
                     ),
                   );
                }
                // 지원하지 않는 메시지 타입
                return Container();
              },
            ),
          ),

          // 메시지 입력 필드
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지 입력...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white, // React 스타일 배경색 적용
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      ),
                       keyboardType: TextInputType.text,
                       maxLines: null, // 여러 줄 입력 가능
                      style: TextStyle(color: Colors.black), // React 스타일 텍스트 색상 적용
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage, // 메시지 전송 메서드 연결
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _bgMain, // React 스타일 배경색 적용
    );
  }
}
