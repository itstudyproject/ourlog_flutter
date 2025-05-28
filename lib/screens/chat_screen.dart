import 'package:flutter/material.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 메시지 로드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _loadMessages();
    });
  }

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
           0.0, // reverse: true 이므로 0.0이 최하단입니다.
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

    // 로딩 상태 표시
    if (chatProvider.isMessagesLoading && chatProvider.currentChannelMessages.isEmpty) {
       return Scaffold(
          appBar: AppBar(
            title: Text(widget.channel.name ?? '채팅'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: const Center(child: CircularProgressIndicator()),
          backgroundColor: Colors.black87,
       );
    }

    // 에러 메시지 표시
    if (chatProvider.messagesErrorMessage != null) {
       return Scaffold(
          appBar: AppBar(
             title: Text(widget.channel.name ?? '채팅'),
             backgroundColor: Colors.black,
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
          backgroundColor: Colors.black87,
       );
    }


    // 채팅 화면 UI
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name ?? '채팅'),
         backgroundColor: Colors.black,
         foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // 스크롤 컨트롤러 연결
              reverse: true, // 최신 메시지가 아래로 가도록 목록을 뒤집음
              itemCount: chatProvider.currentChannelMessages.length,
              itemBuilder: (context, index) {
                // 메시지 목록은 reverse 상태이므로, 실제 메시지 객체는 뒤에서부터 가져와야 합니다.
                final message = chatProvider.currentChannelMessages[chatProvider.currentChannelMessages.length - 1 - index];

                // TODO: 메시지 타입에 따른 다른 위젯 표시 (UserMessage, FileMessage 등)
                // 현재는 UserMessage만 간단히 표시
                if (message is UserMessage) {
                   // TODO: 메시지 정렬 및 시간 표시 개선 필요

                   return Align(
                      // 현재 사용자의 메시지는 오른쪽, 상대방 메시지는 왼쪽에 정렬
                      alignment: message.sender?.userId == chatProvider.currentUser?.userId
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                       child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                             color: message.sender?.userId == chatProvider.currentUser?.userId
                                ? Colors.green[200] // 내 메시지 색상
                                : Colors.grey[300], // 상대방 메시지 색상
                             borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                             crossAxisAlignment: message.sender?.userId == chatProvider.currentUser?.userId
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                             children: [
                                // 상대방 닉네임 (1:1 채팅에서 상대방 메시지일 경우만 표시)
                                 if (message.sender?.userId != chatProvider.currentUser?.userId && widget.channel.memberCount == 2)
                                   Text(
                                      chatProvider.userProfiles[message.sender?.userId]?.nickname ?? message.sender?.nickname ?? '알 수 없는 사용자',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                   ),
                                 if (message.sender?.userId != chatProvider.currentUser?.userId && widget.channel.memberCount == 2)
                                    const SizedBox(height: 4),

                                // 메시지 내용
                                Text(
                                  message.message,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                // TODO: 메시지 시간 표시
                                // Text(
                                //   DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(message.createdAt)),
                                //   style: TextStyle(fontSize: 10, color: Colors.black54),
                                // ),
                             ],
                          ),
                       ),
                   );
                } else if (message is FileMessage) {
                   // TODO: 파일 메시지 표시
                   return Align(
                      alignment: message.sender?.userId == chatProvider.currentUser?.userId
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                             color: message.sender?.userId == chatProvider.currentUser?.userId
                                ? Colors.blue[200] // 내 파일 메시지 색상
                                : Colors.orange[200], // 상대방 파일 메시지 색상
                             borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                Icon(Icons.insert_drive_file, size: 18, color: Colors.black87),
                                SizedBox(width: 4),
                                Flexible(
                                   child: Text(
                                     message.name ?? '파일', // message.name이 null인 경우 '파일'로 표시
                                     style: const TextStyle(color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                   ),
                                ),
                             ],
                          )
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
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      ),
                       keyboardType: TextInputType.text,
                       maxLines: null, // 여러 줄 입력 가능
                      style: TextStyle(color: Colors.black),
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
      backgroundColor: Colors.black87,
    );
  }
}
