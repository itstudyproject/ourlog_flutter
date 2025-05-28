// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class UserProfile {
  final int userId;
  final String nickname;
  final String? profileImageUrl;

  UserProfile({
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? json['id'],
      nickname: json['nickname'] ?? '알 수 없는 사용자',
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class ChatProvider with ChangeNotifier {
  User? _currentUser;
  bool _isSendbirdInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupChannel> _channels = [];
  bool _isChannelsLoading = false;
  String? _channelsErrorMessage;

  final Map<String, UserProfile> _userProfiles = {};

  List<BaseMessage> _currentChannelMessages = [];
  bool _isMessagesLoading = false;
  String? _messagesErrorMessage;
  MessageCollection? _messageCollection;

  static const String _appId = 'C13DF699-49C2-474D-A2B4-341FBEB354EE';

  User? get currentUser => _currentUser;

  bool get isSendbirdInitialized => _isSendbirdInitialized;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<GroupChannel> get channels => _channels;

  bool get isChannelsLoading => _isChannelsLoading;

  String? get channelsErrorMessage => _channelsErrorMessage;

  Map<String, UserProfile> get userProfiles => _userProfiles;

  List<BaseMessage> get currentChannelMessages => _currentChannelMessages;

  bool get isMessagesLoading => _isMessagesLoading;

  String? get messagesErrorMessage => _messagesErrorMessage;

  Future<void> initializeAndConnect(
      String userId,
      String accessToken,
      String jwtToken,
      ) async {
    if (_isSendbirdInitialized) {
      if (_channels.isEmpty && _currentUser != null) {
        fetchMyGroupChannels(jwtToken);
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SendbirdChat.init(appId: _appId);

      debugPrint('Sendbird SDK initialized successfully. Connecting...');

      _currentUser = await SendbirdChat.connect(
        userId,
        accessToken: accessToken,
      );

      debugPrint('Sendbird connection successful: ${_currentUser?.userId}');
      _isSendbirdInitialized = true;

      fetchMyGroupChannels(jwtToken);
    } catch (e) {
      debugPrint('초기화 또는 연결 실패: $e');
      _errorMessage = '초기화 또는 연결 실패: ${e.toString()}';
      _isSendbirdInitialized = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyGroupChannels(String jwtToken) async {
    if (!_isSendbirdInitialized || _currentUser == null) {
      _channelsErrorMessage = '채팅 시스템에 연결되지 않았습니다.';
      notifyListeners();
      return;
    }

    _isChannelsLoading = true;
    _channelsErrorMessage = null;
    notifyListeners();

    try {
      final query = GroupChannelListQuery()..limit = 100;
      final fetchedChannels = await query.next();

      _channels = fetchedChannels;

      final profileTasks =
      fetchedChannels.map((channel) async {
        if (channel.memberCount == 2 && _currentUser != null) {
          final otherUser = channel.members.firstWhere(
                (m) => m.userId != _currentUser!.userId,
            orElse: () => channel.members.first,
          );
          final backendUserId = int.tryParse(otherUser.userId);
          if (backendUserId != null) {
            final profileResult = await AuthService.fetchProfile(
              backendUserId,
              jwtToken,
            );
            if (profileResult['success'] &&
                profileResult['profile'] != null) {
              final userProfile = UserProfile.fromJson(
                profileResult['profile'],
              );
              _userProfiles[otherUser.userId] = userProfile;
            }
          }
        }
      }).toList();

      await Future.wait(profileTasks);
    } catch (e) {
      debugPrint('Failed to fetch group channels: $e');
      _channelsErrorMessage = '채널 목록 로딩 실패: ${e.toString()}';
    } finally {
      _isChannelsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(GroupChannel channel) async {
    if (_currentUser == null) {
      _messagesErrorMessage = '채팅 시스템에 연결되지 않았습니다.';
      notifyListeners();
      return;
    }

    if (_messageCollection != null &&
        _messageCollection!.channel.channelUrl != channel.channelUrl) {
      debugPrint('Disposing previous MessageCollection.');
      _messageCollection?.dispose();
      _messageCollection = null;
    }

    _isMessagesLoading = true;
    _messagesErrorMessage = null;
    _currentChannelMessages = [];
    notifyListeners();

    try {
      debugPrint('Loading messages for channel: ${channel.channelUrl}');

      _messageCollection = MessageCollection(
          channel: channel,
          handler: MyMessageCollectionHandler(),
          params: MessageListParams()
      );

      await _messageCollection!.initialize();

      debugPrint(
        'MessageCollection initialized. Initial messages loaded: ${_messageCollection!.messageList.length}',
      );
      _currentChannelMessages = [..._messageCollection!.messageList];
      notifyListeners();

      _messagesErrorMessage = null;
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      _messagesErrorMessage = '메시지 로드 실패: ${e.toString()}';
      _currentChannelMessages = [];
    } finally {
      _isMessagesLoading = false;
      notifyListeners();
    }
  }

  void disposeMessageCollection() {
    debugPrint('Disposing MessageCollection.');
    _messageCollection?.dispose();
    _messageCollection = null;
    _currentChannelMessages = [];
    _isMessagesLoading = false;
    _messagesErrorMessage = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    disposeMessageCollection();
    if (_currentUser != null) {
      debugPrint('Disconnecting from Sendbird...');
      await SendbirdChat.disconnect();
      debugPrint('Sendbird disconnected.');
      _currentUser = null;
      _isSendbirdInitialized = false;
      _channels = [];
      _userProfiles.clear();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchSendbirdAuthInfo(String jwtToken, int backendUserId) async {
    try {
      // AuthProvider에서 현재 로그인된 사용자 ID 가져오기
      // ChatProvider는 AuthProvider에 의존성을 가지므로 context를 통해 접근하거나 별도의 주입 필요
      // 여기서는 예시로 userId를 가져온다고 가정합니다.
      // 실제 코드에서는 ChatProvider가 생성될 때 AuthProvider 인스턴스를 받거나,
      // fetchSendbirdAuthInfo 호출 시 userId를 인자로 받도록 수정해야 합니다.
      // 임시로 AuthProvider를 직접 Provider.of로 접근합니다 (ChatProvider 외부에서 호출 시 문제될 수 있음).
      // 더 나은 설계는 ChatProvider에 userId를 주입하거나, 함수 인자로 받는 것입니다.
      // 현재 구조에서는 이 함수가 ChatProvider 내부에서 호출되지 않으므로 직접 Provider 접근은 어려울 수 있습니다.
      // ChatListScreen에서 이 함수를 호출하고 있으므로, ChatListScreen에서 AuthProvider에 접근하여 userId를 가져와 전달하는 것이 더 적절합니다.
      // TODO: ChatListScreen에서 userId를 가져와 fetchSendbirdAuthInfo 함수 인자로 전달하도록 수정 필요
      // 현재는 수정된 fetchSendbirdToken의 두 번째 인자가 null이 될 수 있습니다.

      // 임시 방편으로 JWT 토큰에서 다시 userId를 추출 시도 (이상적으로는 이미 가지고 있어야 함)

      final authInfo = await AuthService.fetchSendbirdToken(jwtToken, backendUserId); // <-- userId 인자 전달
      if (authInfo != null &&
          authInfo['userId'] != null &&
          authInfo['accessToken'] != null) {
        return {
          'userId': authInfo['userId'].toString(),
          'accessToken': authInfo['accessToken'],
        };
      } else {
        _errorMessage =
            authInfo?['message'] ?? 'Sendbird 인증 정보를 가져오는데 실패했습니다.';
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching Sendbird auth info: $e');
      _errorMessage = 'Sendbird 인증 정보 요청 중 오류가 발생했습니다.';
      return null;
    }
  }

  @override
  void dispose() {
    disposeMessageCollection();
    super.dispose();
  }

  Future<void> shutdown() async {
    await disconnect();
  }
}

// MyMessageCollectionHandler 클래스 정의
class MyMessageCollectionHandler extends MessageCollectionHandler {
  // 내부 메시지 저장소 (예: 화면에 표시할 메시지 리스트)
  final List<BaseMessage> _messages = [];

  // 메시지 추가 시 호출
  @override
  void onMessagesAdded(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    // 메시지 추가 시 처리 로직 구현
    print('Messages added: ${messages.length}');

    if (channel != null) { // Null 체크 추가
      // 1. 기존 메시지 리스트에 새 메시지 추가
      _messages.addAll(messages);

      // 2. 메시지 리스트를 ID 기준으로 정렬 (예: 시간 순)
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 3. UI 갱신 호출 (가상 함수)
      _refreshUI();
    } else {
      print('Messages added event received, but channel is null.');
    }
  }

  // 메시지 수정 시 호출
  @override
  void onMessagesUpdated(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    // 메시지 업데이트 시 처리 로직 구현
    print('Messages updated: ${messages.length}');

    if (channel != null) { // Null 체크 추가
      for (var updatedMsg in messages) {
        // 1. 기존 메시지 리스트에서 해당 메시지 ID 찾기
        int index = _messages.indexWhere((msg) => msg.messageId == updatedMsg.messageId);
        if (index != -1) {
          // 2. 기존 메시지 교체
          _messages[index] = updatedMsg;
        }
      }

      // 3. UI 갱신
      _refreshUI();
    } else {
      print('Messages updated event received, but channel is null.');
    }
  }

  // 메시지 삭제 시 호출
  @override
  void onMessagesDeleted(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    // 메시지 삭제 시 처리 로직 구현
    print('Messages deleted: ${messages.length}');

    if (channel != null) { // Null 체크 추가
      for (var deletedMsg in messages) {
        // 1. 메시지 리스트에서 삭제 대상 메시지 제거
        _messages.removeWhere((msg) => msg.messageId == deletedMsg.messageId);
      }

      // 2. UI 갱신
      _refreshUI();
    } else {
      print('Messages deleted event received, but channel is null.');
    }
  }

  // 채널 정보 업데이트 시 호출
  @override
  void onChannelUpdated(
      GroupChannelContext context, GroupChannel channel) {
    // 채널 정보 업데이트 시 처리 로직 구현
    if (channel != null) { // Null 체크 추가
      print('Channel updated: ${channel.channelUrl}');
      // 예: 채널 이름이나 멤버 변경을 UI에 반영
      _refreshChannelInfo(channel);
    } else {
      print('Channel updated event received, but channel is null.');
    }
  }

  // 채널 삭제 시 호출
  @override
  void onChannelDeleted(GroupChannelContext context, String deletedChannelUrl) {
    print('Channel deleted: $deletedChannelUrl');

    // 예: 채널 목록에서 제거, 해당 채널 화면 종료 처리
    _handleChannelDeletion(deletedChannelUrl);
  }

  // 큰 메시지 갭 발견 시 호출
  @override
  void onHugeGapDetected() {
    print('Huge gap detected.');

    // 예: 누락된 메시지 재요청
    _requestMessageSync();
  }

  // UI 갱신 (예시)
  void _refreshUI() {
    // 실제 앱에서는 여기서 상태관리 라이브러리나 setState 등으로 UI 갱신
    print('UI refreshed with ${_messages.length} messages.');
  }

  // 채널 정보 갱신 처리 (예시)
  void _refreshChannelInfo(GroupChannel channel) {
    // 채널명, 멤버, 커버 이미지 등 갱신 후 UI 반영
    print('Channel info refreshed: ${channel.name}');
  }

  // 채널 삭제 처리 (예시)
  void _handleChannelDeletion(String channelUrl) {
    // 채널 목록에서 제거, 필요하면 화면 닫기 처리
    print('Handled deletion of channel: $channelUrl');
  }

  // 메시지 동기화 요청 (예시)
  void _requestMessageSync() {
    // 네트워크 호출 등으로 누락된 메시지 다시 로드하는 로직 구현
    print('Requested message sync to fill gap.');
  }
}
