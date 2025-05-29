// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';
// UserListQueryParams는 sendbird_chat_sdk.dart를 통해 접근 가능합니다.
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

class ChatProvider with ChangeNotifier implements MessageCollectionHandler {
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

  @override
  void onMessagesAdded(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    debugPrint('Messages added: ${messages.length}');
    _currentChannelMessages.addAll(messages);
    notifyListeners();
    debugPrint('Messages list updated, new count: ${_currentChannelMessages.length}');
  }

  @override
  void onMessagesUpdated(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    debugPrint('Messages updated: ${messages.length}');
    for (var updatedMsg in messages) {
      final index = _currentChannelMessages
          .indexWhere((msg) => msg.messageId == updatedMsg.messageId);
      if (index != -1) {
        _currentChannelMessages[index] = updatedMsg;
      }
    }
    notifyListeners();
    debugPrint('Messages list updated after edits.');
  }

  @override
  void onMessagesDeleted(
      MessageContext context, GroupChannel channel, List<BaseMessage> messages) {
    debugPrint('Messages deleted: ${messages.length}');
    for (var deletedMsg in messages) {
      _currentChannelMessages
          .removeWhere((msg) => msg.messageId == deletedMsg.messageId);
    }
    notifyListeners();
    debugPrint('Messages list updated after deletions.');
  }

  @override
  void onChannelUpdated(
      GroupChannelContext context, GroupChannel channel) {
    debugPrint('Channel updated: ${channel.channelUrl}');
    final index = _channels.indexWhere((c) => c.channelUrl == channel.channelUrl);
    if (index != -1) {
      _channels[index] = channel;
      notifyListeners();
      debugPrint('Channel list updated.');
    }
  }

  @override
  void onChannelDeleted(GroupChannelContext context, String deletedChannelUrl) {
    debugPrint('Channel deleted: $deletedChannelUrl');
    _channels.removeWhere((channel) => channel.channelUrl == deletedChannelUrl);
    notifyListeners();
    debugPrint('Channel list updated after deletion.');

    if (_messageCollection?.channel.channelUrl == deletedChannelUrl) {
      disposeMessageCollection();
    }
  }

  @override
  void onHugeGapDetected() {
    debugPrint('Huge gap detected. Re-fetching messages...');
  }

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
        handler: this,
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
      notifyListeners();
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
      final authInfo = await AuthService.fetchSendbirdToken(jwtToken, backendUserId);
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

  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // 사용자 닉네임으로 Sendbird 사용자 검색
  Future<List<User>> searchUsersByNickname(String query) async {
    if (!_isSendbirdInitialized || _currentUser == null) {
      debugPrint('Sendbird not initialized or user not connected.');
      return [];
    }

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      debugPrint('Searching Sendbird users with nickname keyword: $query');

      // ApplicationUserListQuery 인스턴스 생성
      final queryParams = ApplicationUserListQuery(nicknameStartsWithFilter: query)
        ..nicknameStartsWithFilter = query.trim()
        ..limit = 20; // 필요 시 검색 결과 제한

      // loadNext()는 다음 페이지 사용자 목록을 비동기로 가져옴
      final users = await queryParams.next();

      // 현재 로그인된 유저 제외
      users.removeWhere((user) => user.userId == _currentUser!.userId);

      debugPrint('Search results: ${users.length} users found.');
      return users;
    } catch (e, stacktrace) {
      debugPrint('Sendbird user search failed: $e');
      debugPrint('Stacktrace: $stacktrace');
      return [];
    }
  }

  // TODO: 1:1 채팅 채널 개설 로직 추가 (_create1to1Channel 또는 유사한 메서드)
  Future<GroupChannel?> create1to1Channel(String targetUserId) async {
     if (!_isSendbirdInitialized || _currentUser == null) {
        debugPrint('Sendbird not initialized or user not connected. Cannot create channel.');
        // setErrorMessage('채팅 시스템에 연결되지 않았습니다.');
        return null;
     }
     if (targetUserId == _currentUser!.userId) {
        debugPrint('Cannot create channel with yourself.');
        // setErrorMessage('자신과 채팅할 수 없습니다.');
        return null;
     }

     try {
        debugPrint('Creating 1:1 channel with user ID: $targetUserId');
        final params = GroupChannelCreateParams();
        params.userIds = [targetUserId, _currentUser!.userId]; // 1:1 채팅 멤버 추가
        params.isDistinct = true; // 기존 1:1 채널이 있으면 재사용

        final channel = await GroupChannel.createChannel(params);
        debugPrint('1:1 channel created or found: ${channel.channelUrl}');

        // 새롭게 생성되거나 찾아진 채널을 채널 목록에 추가 (이미 있다면 업데이트) 
        // Sendbird 이벤트 핸들러에서 자동으로 처리될 수도 있지만, 즉각적인 반영을 위해 수동 추가 가능
        final index = _channels.indexWhere((c) => c.channelUrl == channel.channelUrl);
        if (index == -1) {
          _channels.insert(0, channel); // 목록 맨 앞에 추가
        } else {
           _channels[index] = channel; // 기존 채널 정보 업데이트
        }
        notifyListeners();

        // 상대방 프로필 정보도 함께 가져오는 로직 (fetchMyGroupChannels 참고)
        final backendUserId = int.tryParse(targetUserId);
        if (backendUserId != null) {
           // 현재 JWT 토큰이 필요하므로, create1to1Channel 메서드에 JWT 토큰을 전달해야 할 수 있습니다.
           // 또는 AuthProvider를 통해 JWT 토큰에 접근하는 방식 사용
           // 현재 코드 구조상 ChatProvider는 AuthProvider에 직접 접근하지 않으므로, 토큰 전달이 필요합니다.
           // 임시로 여기서는 프로필 정보 가져오는 로직 생략 또는 수정 필요
           debugPrint('TODO: Fetch user profile for $targetUserId after channel creation.');
        }

        return channel;
     } catch (e) {
        debugPrint('Failed to create 1:1 channel: $e');
        // setErrorMessage('채널 개설 실패: ${e.toString()}');
        return null; // 에러 발생 시 null 반환
     }
  }
}

