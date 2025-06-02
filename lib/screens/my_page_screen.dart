import 'package:flutter/material.dart';
import 'package:ourlog/models/post.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:ourlog/models/trade.dart';

import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/main_layout.dart';
import 'art/bid_history_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ProfileService _service = ProfileService();
  int? _userId;
  UserProfile? _profile;
  bool _loading = true;

  // ✅ activeTab 상태에 'my-posts'와 'bookmark' 추가
  String _activeTab = 'purchase-bid'; // 'purchase-bid', 'sale', 'my-posts', 'bookmark'

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId;
    _load();
  }

  Future<void> _load() async {
    if (_userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = await _service.fetchProfile(_userId!);
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // 에러 처리
    } finally {
      if (mounted) {
        debugPrint('★★★ fetchProfile 성공, 이미지 URL 확인: thumbnailImagePath=${_profile?.thumbnailImagePath}, profileImageUrl=${_profile?.profileImageUrl}');
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }
    return MainLayout(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileCard(),
            SizedBox(height: 30),
            _SectionTitle('메뉴'),
            SizedBox(height: 10),
            // ✅ 메뉴 탭 버튼 UI 수정
            SingleChildScrollView( // 버튼이 많아질 수 있으므로 가로 스크롤 가능하게
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('구매/입찰목록', 'purchase-bid'),
                  _buildTabButton('판매목록/현황', 'sale'),
                  _buildTabButton('내 글 목록', 'my-posts'), // '내 글 목록' 탭 추가
                  _buildTabButton('관심목록', 'bookmark'), // '북마크'를 '관심목록'으로 변경
                ],
              ),
            ),
            SizedBox(height: 20), // 탭 버튼과 내용 사이 간격
            // ✅ activeTab에 따라 다른 내용 표시
            Flexible( // 남은 공간을 차지하도록 Flexible로 변경
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 탭 버튼을 생성하는 도우미 위젯
  Widget _buildTabButton(String label, String tabName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // 버튼 사이 간격
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _activeTab = tabName;
          });
        },
        style: ElevatedButton.styleFrom(
          // ✅ 활성 탭에 따라 색상 변경
          backgroundColor: _activeTab == tabName ? Theme.of(context).primaryColor : Color(0xFF232323),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // ✅ 탭 내용 위젯을 반환하는 도우미 함수
  Widget _buildTabContent() {
    if (_userId == null) {
      return const Center(
        child: Text(
          '로그인이 필요합니다.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    switch (_activeTab) {
      case 'purchase-bid':
        // ✅ BidHistoryScreen 사용
        return BidHistoryScreen(); // userId는 BidHistoryScreen 내부에서 AuthProvider로 가져옴
      case 'sale':
        // ✅ 판매 목록 위젯
        return _SaleTradeList(userId: _userId!);
      case 'my-posts':
        // ✅ 내 글 목록 위젯
        return _UserPostGrid(userId: _userId!, listType: 'my-posts');
      case 'bookmark':
        // ✅ 관심목록 위젯
        return _UserPostGrid(userId: _userId!, listType: 'bookmark');
      default:
        return const Center(child: Text('탭 오류'));
    }
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF333333),
            backgroundImage: NetworkImage(
              'http://10.100.204.171:8080' + (_profile?.thumbnailImagePath ?? ''),
              headers: {
                'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
              },
            ) as ImageProvider,

          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.nickname,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '팔로워: ${_profile!.followCnt}   팔로잉: ${_profile!.followingCnt}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF333333),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () async {
                          if (_userId == null) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }
                          final result = await Navigator.pushNamed(
                            context,
                            '/mypage/edit',
                            arguments: _userId!,
                          ) as bool?;
                          if (result == true) {
                            _load();
                          }
                        },
                        child: Text(
                          '프로필수정',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    _actionButton('회원정보수정', '/mypage/account/edit'),
                    SizedBox(width: 8),
                    _actionButton(
                      '회원탈퇴',
                      '/mypage/account/delete',
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, String route,
      {Color backgroundColor = const Color(0xFF333333)}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () {
          if (_userId == null) {
            Navigator.pushNamed(context, '/login');
            return;
          }
          Navigator.pushNamed(
            context,
            route,
            arguments: _userId!,
          );
        },
        child: Text(label, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _menuButton(String label, String route) {
    // ✅ 이 기존 메뉴 버튼은 더 이상 사용하지 않음. _buildTabButton 사용
    return SizedBox.shrink(); // 숨김
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ✅ 판매 목록/현황 표시를 위한 새로운 위젯 (StatefulWidget 또는 StatelessWidget으로 만들 수 있음)
// 여기서는 간단히 틀만 잡고, 실제 데이터 가져오기 및 표시 로직은 추후 추가
class _SaleTradeList extends StatefulWidget {
  final int userId;
  const _SaleTradeList({Key? key, required this.userId}) : super(key: key);

  @override
  __SaleTradeListState createState() => __SaleTradeListState();
}

class __SaleTradeListState extends State<_SaleTradeList> {
  bool _isLoading = true;
  List<Post> _sellingPosts = []; // 판매 중인 경매 (Post 모델 사용)
  List<Post> _soldPosts = []; // 판매 완료/유찰된 경매 (Post 모델 사용)
  String? _errorMessage;
  Timer? _timer; // 남은 시간 표시를 위한 타이머
  DateTime _currentTime = DateTime.now(); // 남은 시간 계산 기준 시간
  static const String baseUrl = "http://10.100.204.171:8080/ourlog"; // 필요에 따라 MyPageScreen에서 전달받거나 전역 상수로

  @override
  void initState() {
    super.initState();
    _fetchUserSales();
    // 남은 시간 계산을 위한 타이머 시작 (판매 중인 목록이 있을 때만 실행되도록 추후 최적화 가능)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Future<Map<String, String>> _getHeaders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      debugPrint('SaleTradeList: 인증 토큰 없음. 로그인 페이지로 이동 필요.');
      throw Exception('인증 토큰이 없습니다.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchUserSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sellingPosts = [];
      _soldPosts = [];
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/profile/sales/${widget.userId}'); // 판매 목록 API 엔드포인트

      final response = await http.get(uri, headers: headers);
      debugPrint('SaleTradeList API 응답 상태 코드: ${response.statusCode}');
      debugPrint('SaleTradeList API 응답 본문: ${response.body}');


      if (response.statusCode == 403) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // ✅ 웹 백엔드 응답 구조에 맞춰 파싱 (SaleEntry 유사)
        // currentSales, expiredSales 키 사용 및 List<dynamic>으로 캐스팅
        final List<dynamic> sellingJson = data['currentSales'] ?? []; // 웹 코드의 currentBids -> 여기서는 currentSales로 예상
        final List<dynamic> soldJson = data['expiredSales'] ?? []; // 웹 코드의 wonTrades -> 여기서는 expiredSales로 예상

        debugPrint('sellingJson count: ${sellingJson.length}');
        debugPrint('soldJson count: ${soldJson.length}');


        // Post 모델에 맞게 변환 (TradeDTO 포함)
        // 백엔드 SaleEntry 구조를 Flutter Post 모델로 변환하는 로직 필요
        // Post.fromJson은 PostDTO 전체 구조를 예상하므로, 여기서 PostDTO 형태로 매핑하여 전달
        List<Post> sellingList = sellingJson.map((item) {
          // SaleEntry 형태의 item을 PostDTO 형태로 변환하여 Post.fromJson에 전달
          return Post.fromJson({
            'postId': item['postId'],
            'userId': item['sellerId'], // 판매자 ID
            'title': item['postTitle'],
            // description 필드는 SaleEntry에 없으므로 null 또는 빈 문자열 처리
            'content': null, // SaleEntry에 content 없음
            'nickname': item['sellerNickname'] ?? '알 수 없음', // 판매자 닉네임 (SaleEntry에 있다고 가정)
            'fileName': item['postImage'], // 대표 이미지 파일 이름

            // 이미지 경로 관련 필드: SaleEntry의 postImage를 활용
            'thumbnailImagePath': item['postImage'],
            'resizedImagePath': item['postImage'],
            // originImagePath는 보통 여러 개일 수 있지만, SaleEntry에는 단일 이미지 경로만 있으므로 리스트에 담아 처리
            'originImagePath': item['postImage'] != null ? [item['postImage']] : [],
            // pictureDTOList는 Post의 상세 정보에 포함되지만, 목록에서는 대표 이미지만 사용한다고 가정하고 간단히 구성
            'pictureDTOList': item['postImage'] != null ? [{'uuid': item['postImage'], 'path': item['postImage']}] : [], // 간소화된 PictureDTO 리스트

            'boardNo': 5, // 아트 게시판은 boardNo 5

            // 나머지 PostDTO 필드는 SaleEntry에 없으므로 기본값 또는 null 처리
            'views': 0, 'tag': null, 'followers': 0, 'downloads': 0, 'favoriteCnt': 0,
            'profileImage': item['sellerProfileImage'] ?? null, // 판매자 프로필 이미지 (SaleEntry에 있다고 가정)
            'replyCnt': 0, 'regDate': null, 'modDate': null,
            'liked': false, // 판매 목록에서는 좋아요 상태 정보 불필요

            'tradeDTO': { // TradeDTO 정보 매핑
              'tradeId': item['tradeId'],
              'postId': item['postId'],
              'sellerId': item['sellerId'],
              'bidderId': item['bidderId'],
              'bidderNickname': item['bidderNickname'],
              'startPrice': item['startPrice'],
              'highestBid': item['highestBid'],
              'nowBuy': item['nowBuy'],
              // ✅ SaleEntry의 tradeStatus는 boolean이므로 Flutter 모델의 TradeStatus (Enum 또는 String)에 맞게 변환 필요
              // 만약 Post 모델의 TradeDTO.tradeStatus가 String이면, boolean 값을 문자열로 변환 (예: true -> 'COMPLETED', false -> 'ACTIVE')
              // 현재 Post 모델의 TradeDTO.tradeStatus는 String으로 예상되므로 변환 로직 추가
              'tradeStatus': item['tradeStatus'] == true ? 'COMPLETED' : 'ACTIVE', // boolean 값을 문자열로 변환하여 매핑
              // ✅ 날짜/시간 문자열을 DateTime 객체로 변환
              'startBidTime': item['startBidTime'] != null ? DateTime.parse(item['startBidTime']) : null, // DateTime.parse 사용
              'lastBidTime': item['lastBidTime'] != null ? DateTime.parse(item['lastBidTime']) : null,   // DateTime.parse 사용
            },
          });
        }).where((post) { // ✅ 웹 코드 필터링 로직 적용
            // 현재 판매 중인 목록: tradeStatus === false && bidderId === currentUserId && sellerId !== currentUserId
            return (post.tradeDTO?.tradeStatus == 'ACTIVE' && post.tradeDTO?.bidderId == widget.userId && post.tradeDTO?.sellerId != widget.userId);
        }).toList();


        List<Post> soldList = soldJson.map((item) {
          return Post.fromJson({
            'postId': item['postId'],
            'userId': item['sellerId'],
            'title': item['postTitle'],
            'content': null,
            'nickname': item['sellerNickname'] ?? '알 수 없음',
            'fileName': item['postImage'],
            'thumbnailImagePath': item['postImage'],
            'resizedImagePath': item['postImage'],
            'originImagePath': item['postImage'] != null ? [item['postImage']] : [],
            'pictureDTOList': item['postImage'] != null ? [{'uuid': item['postImage'], 'path': item['postImage']}] : [],

            'boardNo': 5,

            'views': 0, 'tag': null, 'followers': 0, 'downloads': 0, 'favoriteCnt': 0,
            'profileImage': null,
            'replyCnt': 0, 'regDate': null, 'modDate': null,
            'liked': false,

            'tradeDTO': { // TradeDTO 정보 매핑
              'tradeId': item['tradeId'],
              'postId': item['postId'],
              'sellerId': item['sellerId'],
              'bidderId': item['bidderId'],
              'bidderNickname': item['bidderNickname'],
              'startPrice': item['startPrice'],
              'highestBid': item['highestBid'],
              'nowBuy': item['nowBuy'],
              'tradeStatus': item['tradeStatus'] == true ? 'COMPLETED' : 'ACTIVE', // boolean 값을 문자열로 변환하여 매핑
              'startBidTime': item['startBidTime'] != null ? DateTime.parse(item['startBidTime']) : null, // DateTime.parse 사용
              'lastBidTime': item['lastBidTime'] != null ? DateTime.parse(item['lastBidTime']) : null,   // DateTime.parse 사용
            },
          });
        }).where((post) { // ✅ 웹 코드 필터링 로직 적용
            // 판매 완료된 목록: tradeStatus === true && sellerId !== currentUserId && (buyerId === currentUserId || bidderId === currentUserId)
             // wonTrades는 이미 tradeStatus === true 인 데이터라고 가정하고 필터링
            return (post.tradeDTO?.sellerId != widget.userId && (post.tradeDTO?.bidderId == widget.userId || post.tradeDTO?.bidderId == widget.userId));
        }).toList();


        setState(() {
          _sellingPosts = sellingList;
          _soldPosts = soldList;
          _isLoading = false;
        });

      } else if (response.statusCode == 404) { // 404도 데이터 없음으로 처리
        setState(() {
          _sellingPosts = [];
          _soldPosts = [];
          _isLoading = false;
        });
        debugPrint('SaleTradeList: 해당 유저의 판매 목록이 없습니다 (404)');
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('판매 목록 불러오기 실패: $e');
      setState(() {
        _errorMessage = '판매 목록을 불러오는 데 실패했습니다: ${e.toString()}';
        _isLoading = false;
        _sellingPosts = [];
        _soldPosts = [];
      });
    }
  }

  // 남은 시간 계산 및 포맷팅 함수 (Post 모델의 getTimeLeft 활용 대신 직접 구현)
  String _getRemainingTime(Post item) {
    // TradeDTO가 Post에 포함되어 있고 tradeStatus가 String 타입이라고 가정 ('ACTIVE', 'COMPLETED')
    if (item.tradeDTO == null || (item.tradeDTO!.tradeStatus != 'ACTIVE')) { // tradeStatus가 ACTIVE가 아니면 종료
      return '경매 종료';
    }

    // ✅ 남은 시간 직접 계산 및 포맷팅 (bid_history_screen.dart 참고)
    final endTime = item.tradeDTO?.lastBidTime;
    if (endTime == null) return "시간 정보 없음";

    final diff = endTime.difference(_currentTime);

    if (diff.isNegative) {
      return "경매 종료";
    }

    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (days > 0) {
      return "${days}일 ${hours}시간 ${minutes}분 ${seconds}초 남음";
    } else if (hours > 0) {
      return "${hours}시간 ${minutes}분 ${seconds}초 남음";
    } else if (minutes > 0) {
      return "${minutes}분 ${seconds}초 남음";
    } else {
      return "${seconds}초 남음";
    }
  }

  // 가격 포맷팅
  String _formatPrice(int? price) {
    if (price == null) return '가격 정보 없음';
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  // 작품 상세 페이지 이동
  void _handleArtworkClick(int postId) {
    Navigator.pushNamed(
      context,
      '/Art',
      arguments: postId.toString(),
    );
  }

  // 원본 이미지 다운로드 (판매 완료 항목)
  // item.originImagePath는 List<String> 또는 String? 일 수 있으므로 안전하게 접근
  void _handleDownloadOriginal(Post item) {
    // originImagePath가 List<String> 타입이고 비어있지 않은지 확인
    if (item.originImagePath == null || item.originImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다운로드할 이미지가 없습니다.')),
      );
      return;
    }
    // 첫 번째 원본 이미지 경로를 사용 (웹 코드 참고)
    // 경로가 /ourlog 로 시작하면 전체 URL 구성, 아니면 baseUrl 추가
    // ✅ 웹 코드에서는 postImage 필드를 사용하므로 item.fileName 또는 item.thumbnailImagePath 사용
    final imagePath = item.fileName ?? item.thumbnailImagePath ?? (item.originImagePath!.isNotEmpty ? item.originImagePath!.first : null);

    if (imagePath == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('다운로드할 이미지 경로가 유효하지 않습니다.')),
       );
       return;
    }

    final imageUrl = imagePath.startsWith('/ourlog')
        ? 'http://10.100.204.171:8080${imagePath}' // 도메인 추가
        : '$baseUrl/picture/display/${imagePath}'; // imageBaseUrl 대체

    // TODO: Flutter에서 파일 다운로드 로직 구현 필요 (url_launcher, path_provider, dio 등 패키지 활용)
    debugPrint('Download original image URL: $imageUrl');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('다운로드 기능 미구현: $imageUrl')),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_sellingPosts.isEmpty && _soldPosts.isEmpty) {
      return const Center(child: Text('판매 내역이 없습니다.'));
    }

    return Expanded(
      child: SingleChildScrollView( // Column 대신 SingleChildScrollView를 Expanded로 감쌉니다.
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 기존 SingleChildScrollView의 Padding을 옮겨옴
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 판매 중인 경매 목록 섹션
              Text(
                '현재 판매 중인 경매',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _sellingPosts.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sellingPosts.length,
                itemBuilder: (context, index) {
                  final item = _sellingPosts[index];
                  // 현재 최고 입찰가 또는 시작가 표시
                  final currentPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                  return GestureDetector(
                    onTap: () => _handleArtworkClick(item.postId!), // 상세 페이지 이동
                    child: Card( // 웹 코드의 mp-item data 역할
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0), // 패딩 조정 (웹 참고)
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬 (웹 참고)
                          children: [
                            // 이미지 썸네일
                            Container(
                              width: 60, // 크기 조정 (웹 참고)
                              height: 60, // 크기 조정 (웹 참고)
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4), // 모서리 둥글게
                                color: Colors.grey[300],
                              ),
                              clipBehavior: Clip.antiAlias, // 자식 컨텐츠를 모서리 둥글게
                              child: item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg"
                                  ? Image.network(
                                item.getImageUrl(), // Post 모델의 getImageUrl 사용
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30), // 오류 이미지
                              )
                                  : const Center(child: Icon(Icons.image_not_supported, size: 30)), // 이미지 없음 아이콘
                            ),
                            const SizedBox(width: 12),
                            // 상세 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title ?? '제목 없음',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), // 스타일 조정 (웹 참고)
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '현재가: ${_formatPrice(currentPrice)}원',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).primaryColor), // 스타일 조정 (웹 참고)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '남은 시간: ${_getRemainingTime(item)}', // 남은 시간 표시
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), // 스타일 조정 (웹 참고)
                                  ),
                                ],
                              ),
                            ),
                            // 상태 표시
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 패딩 조정 (웹 참고)
                              decoration: BoxDecoration(
                                color: Colors.orange, // 판매 중 상태 색상 (웹 참고)
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('판매 중', style: TextStyle(color: Colors.white, fontSize: 12)), // 텍스트 및 스타일 조정
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : const Text('판매 중인 경매가 없습니다.'),

              const SizedBox(height: 32), // 섹션 간 간격 추가

              // 판매 완료/유찰된 경매 목록 섹션
              Text(
                '기간 만료된 경매',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _soldPosts.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _soldPosts.length,
                itemBuilder: (context, index) {
                  final item = _soldPosts[index];
                  // 낙찰/유찰 가격 (highestBid 또는 startPrice)
                  final finalPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                  // 경매 종료 시간 또는 유찰 시간
                  final endTimeString = item.tradeDTO?.lastBidTime != null
                      ? DateFormat('yyyy.MM.dd HH:mm').format(item.tradeDTO!.lastBidTime!)
                      : '시간 정보 없음';
                  // 상태 (낙찰 또는 유찰)
                  final status = item.tradeDTO?.bidderId != null ? '판매 완료' : '유찰';
                  final statusColor = item.tradeDTO?.bidderId != null ? Colors.green : Colors.grey; // 웹 코드 색상 참고

                  return GestureDetector(
                    onTap: () => _handleArtworkClick(item.postId!), // 상세 페이지 이동
                    child: Card( // 웹 코드의 mp-item data 역할 (sold 또는 failed)
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0), // 패딩 조정 (웹 참고)
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬 (웹 참고)
                          children: [
                            // 이미지 썸네일
                            Container(
                              width: 60, // 크기 조정 (웹 참고)
                              height: 60, // 크기 조정 (웹 참고)
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4), // 모서리 둥글게
                                color: Colors.grey[300],
                              ),
                              clipBehavior: Clip.antiAlias, // 자식 컨텐츠를 모서리 둥글게
                              child: item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg"
                                  ? Image.network(
                                item.getImageUrl(), // Post 모델의 getImageUrl 사용
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30), // 오류 이미지
                              )
                                  : const Center(child: Icon(Icons.image_not_supported, size: 30)), // 이미지 없음 아이콘
                            ),
                            const SizedBox(width: 12),
                            // 상세 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title ?? '제목 없음',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), // 스타일 조정 (웹 참고)
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    // 판매 완료 시 '판매가', 유찰 시 '최고 입찰가'
                                    '${item.tradeDTO?.bidderId != null ? '판매가' : '최고 입찰가'}: ${_formatPrice(finalPrice)}원',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: statusColor), // 스타일 조정 (웹 참고)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                     // 경매 종료 시간 또는 유찰 시간 표시
                                     '종료 시간: $endTimeString',
                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]), // 스타일 조정 (웹 참고)
                                  ),
                                ],
                              ),
                            ),
                            // 상태 표시 및 다운로드 버튼
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 패딩 조정 (웹 참고)
                                  decoration: BoxDecoration(
                                    color: statusColor, // 상태 색상 (웹 참고)
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)), // 텍스트 및 스타일 조정
                                ),
                                const SizedBox(height: 8),
                                // 다운로드 버튼 (판매 완료 && 이미지 있을 때)
                                if (item.tradeDTO?.bidderId != null && item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg")
                                  IconButton(
                                    onPressed: () => _handleDownloadOriginal(item),
                                    icon: const Icon(Icons.download),
                                    tooltip: '원본 이미지 다운로드',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: Colors.grey[600], // 아이콘 색상 조정
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : const Text('기간 만료된 경매가 없습니다.'),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ 사용자의 내 글 목록 또는 관심 목록을 표시하는 위젯
// 웹 프론트의 UserPostGrid 컴포넌트 역할
class _UserPostGrid extends StatefulWidget {
  final int userId;
  final String listType; // 'my-posts' 또는 'bookmark'
  const _UserPostGrid({Key? key, required this.userId, required this.listType}) : super(key: key);

  @override
  __UserPostGridState createState() => __UserPostGridState();
}

class __UserPostGridState extends State<_UserPostGrid> {
  bool _isLoading = true;
  List<Post> _posts = []; // 게시글 목록
  String? _errorMessage;
  static const String baseUrl = "http://10.100.204.171:8080/ourlog";
  static const String imageBaseUrl = "$baseUrl/picture/display/"; // 웹 코드의 imageBaseUrl 참고

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void didUpdateWidget(covariant _UserPostGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // listType이나 userId가 변경되면 데이터 다시 불러오기
    if (widget.listType != oldWidget.listType || widget.userId != oldWidget.userId) {
      _fetchPosts();
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      debugPrint('_UserPostGrid: 인증 토큰 없음. 로그인 페이지로 이동 필요.');
      throw Exception('인증 토큰이 없습니다.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _posts = [];
    });

    try {
      final headers = await _getHeaders();
      String endpoint;
      if (widget.listType == 'my-posts') {
        endpoint = '$baseUrl/followers/getPost/${widget.userId}'; // 웹 코드와 동일한 엔드포인트
      } else if (widget.listType == 'bookmark') {
        endpoint = '$baseUrl/favorites/user/${widget.userId}'; // 웹 코드와 동일한 엔드포인트
      } else {
        setState(() {
          _errorMessage = '알 수 없는 목록 타입: ${widget.listType}';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse(endpoint);
      debugPrint('_UserPostGrid API 요청 URL: $uri');
      debugPrint('_UserPostGrid API 요청 헤더: $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('_UserPostGrid API 응답 상태 코드: ${response.statusCode}');
      debugPrint('_UserPostGrid API 응답 본문: ${response.body}');

      if (response.statusCode == 403) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> postJson = jsonDecode(response.body) ?? [];

        // ✅ Post 모델에 맞게 변환
        List<Post> fetchedPosts = postJson.map((json) => Post.fromJson(json)).toList();

        // 좋아요 상태 등 추가 정보는 Post.fromJson에서 처리될 것으로 가정.
        // 만약 API 응답에 liked 정보가 없다면 별도 API 호출 또는 로직 필요.
        // 여기서는 Post.fromJson에서 liked 정보를 포함한다고 가정하고 별도 Future.wait 제거.

        setState(() {
          _posts = fetchedPosts;
          _isLoading = false;
        });

      } else if (response.statusCode == 404) { // 404도 데이터 없음으로 처리
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        debugPrint('_UserPostGrid: 해당 유저의 ${widget.listType} 목록이 없습니다 (404)');
      }
      else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('${widget.listType} 목록 불러오기 실패: $e');
      setState(() {
        _errorMessage = '목록을 불러오는 데 실패했습니다: ${e.toString()}';
        _isLoading = false;
        _posts = [];
      });
    }
  }

  // 게시글 상세 페이지 이동 함수
  void _handlePostClick(int postId) {
    Navigator.pushNamed(
      context,
      '/Art', // ArtDetailScreen 라우트 이름
      arguments: postId.toString(), // 게시글 ID를 문자열로 전달
    );
  }

  // ✅ 좋아요 토글 함수 (웹 코드 참고)
  Future<void> _handleLikeToggle(Post post) async {
    if (widget.userId == null || post.postId == null) {
      debugPrint("로그인이 필요하거나 작품 정보가 없습니다.");
      // 여기서 Navigator.pushNamed 대신 상위에서 처리하도록 유도하거나,
      // SnackBar 메시지만 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요하거나 작품 정보가 없습니다.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      debugPrint("인증 토큰이 없습니다.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      // Navigator.pushReplacementNamed(context, '/login'); // 필요하다면 로그인 페이지로 이동
      return;
    }

    // Optimistic UI 업데이트
    setState(() {
      _posts = _posts.map((item) {
        if (item.postId == post.postId) {
          final newLiked = !(item.liked ?? false);
          final newFavoriteCnt = (item.favoriteCnt ?? 0) + (newLiked ? 1 : -1);
          return Post(
            postId: item.postId,
            userId: item.userId,
            title: item.title,
            content: item.content,
            nickname: item.nickname,
            fileName: item.fileName,
            boardNo: item.boardNo,
            views: item.views,
            tag: item.tag,
            thumbnailImagePath: item.thumbnailImagePath,
            resizedImagePath: item.resizedImagePath,
            originImagePath: item.originImagePath,
            followers: item.followers,
            downloads: item.downloads,
            favoriteCnt: newFavoriteCnt, // 업데이트된 좋아요 수
            pictureDTOList: item.pictureDTOList,
            profileImage: item.profileImage,
            replyCnt: item.replyCnt,
            regDate: item.regDate,
            modDate: item.modDate,
            tradeDTO: item.tradeDTO,
            liked: newLiked, // 업데이트된 좋아요 상태
          );
        }
        return item;
      }).where((item) => item != null).cast<Post>().toList(); // null 항목 (제거될 항목) 필터링
    });

    try {
      final uri = Uri.parse('$baseUrl/favorites/toggle');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'postId': post.postId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('좋아요 서버 응답 오류: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // 백엔드 응답으로 최종 상태 업데이트 (좋아요 상태 및 카운트)
      if (data.containsKey('favoriteCount') && data.containsKey('favorited')) {
        final int latestFavoriteCnt = data['favoriteCount'];
        final bool userLiked = data['favorited'];

        setState(() {
          _posts = _posts.map((item) {
            if (item.postId == post.postId) {
              // 웹 코드에서는 관심목록 탭에서 좋아요 취소 시 목록에서 제거하는 로직이 있음
              // Flutter에서도 동일하게 적용하려면 여기서 필터링 필요
              if (widget.listType == 'bookmark' && !userLiked) {
                return null; // 제거될 항목 표시
              }
              return Post(
                postId: item.postId,
                userId: item.userId,
                title: item.title,
                content: item.content,
                nickname: item.nickname,
                fileName: item.fileName,
                boardNo: item.boardNo,
                views: item.views,
                tag: item.tag,
                thumbnailImagePath: item.thumbnailImagePath,
                resizedImagePath: item.resizedImagePath,
                originImagePath: item.originImagePath,
                followers: item.followers,
                downloads: item.downloads,
                favoriteCnt: latestFavoriteCnt, // 백엔드 최신 값
                pictureDTOList: item.pictureDTOList,
                profileImage: item.profileImage,
                replyCnt: item.replyCnt,
                regDate: item.regDate,
                modDate: item.modDate,
                tradeDTO: item.tradeDTO,
                liked: userLiked, // 백엔드 최신 값
              );
            }
            return item;
          }).where((item) => item != null).cast<Post>().toList(); // null 항목 (제거될 항목) 필터링
        });

        debugPrint('좋아요 토글 성공: postId ${post.postId}, favorited: $userLiked, count: $latestFavoriteCnt');

      } else {
        debugPrint('좋아요 토글 API 응답 형식 오류: $data');
        // 응답 형식 오류 시에도 optimistic rollback
        _rollbackLikeToggle(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다 (응답 형식 오류). 다시 시도해주세요.')),
        );
      }

    } catch (e) {
      debugPrint('좋아요 토글 실패: ${post.postId}, 오류: $e');
      // 실패 시 optimistic rollback
      _rollbackLikeToggle(post);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 처리에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  // 좋아요 토글 실패 시 UI 롤백 함수
  void _rollbackLikeToggle(Post post) {
    setState(() {
      _posts = _posts.map((item) {
        if (item.postId == post.postId) {
          final rolledBackLiked = !(item.liked ?? false); // Optimistic 업데이트 이전 상태
          final rolledBackFavoriteCnt = (item.favoriteCnt ?? 0) + (rolledBackLiked ? 1 : -1);
          return Post( // 새로운 Post 객체 생성
            postId: item.postId,
            userId: item.userId,
            title: item.title,
            content: item.content,
            nickname: item.nickname,
            fileName: item.fileName,
            boardNo: item.boardNo,
            views: item.views,
            tag: item.tag,
            thumbnailImagePath: item.thumbnailImagePath,
            resizedImagePath: item.resizedImagePath,
            originImagePath: item.originImagePath,
            followers: item.followers,
            downloads: item.downloads,
            favoriteCnt: rolledBackFavoriteCnt,
            pictureDTOList: item.pictureDTOList,
            profileImage: item.profileImage,
            replyCnt: item.replyCnt,
            regDate: item.regDate,
            modDate: item.modDate,
            tradeDTO: item.tradeDTO,
            liked: rolledBackLiked,
          );
        }
        return item;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_posts.isEmpty) {
      final emptyMessage = widget.listType == 'my-posts' ? '작성한 게시글이 없습니다.' : '관심 등록한 게시글이 없습니다.';
      return Center(child: Text(emptyMessage));
    }

    // ✅ 게시글 목록 GridView로 표시
    // MyPageScreen에서 이미 Flexible -> SingleChildScrollView -> Column 구조로 감싸져 있으므로,
    // 여기서 다시 Expanded나 SingleChildScrollView로 감싸는 것이 적절합니다.
    // 단, GridView 자체가 스크롤을 처리하므로, 부모의 SingleChildScrollView와 함께 사용될 때
    // shrinkWrap: true와 physics: const NeverScrollableScrollPhysics()를 사용했었습니다.
    // MyPageScreen에서 Flexible로 감싸고 SingleChildScrollView를 제거했으므로,
    // 이제 여기서 GridView.builder를 Flexible 또는 Expanded로 감싸는 것이 적절합니다.
    // 단, GridView 자체가 스크롤을 처리하므로, 부모의 SingleChildScrollView와 함께 사용될 때
    // shrinkWrap: true와 physics: const NeverScrollableScrollPhysics()를 사용했었습니다.
    // MyPageScreen에서 Flexible로 감싸고 SingleChildScrollView를 제거했으므로,
    // 이제 여기서 GridView.builder를 Flexible 또는 Expanded로 감싸는 것이 적절합니다.
    return GridView.builder(
      shrinkWrap: true, // 이중 스크롤 방지를 위해 필수
      physics: const NeverScrollableScrollPhysics(), // 이중 스크롤 방지를 위해 필수
      padding: const EdgeInsets.all(8.0), // 그리드 패딩
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 한 줄에 2개 항목
        crossAxisSpacing: 8.0, // 가로 간격
        mainAxisSpacing: 8.0, // 세로 간격
        childAspectRatio: 0.7, // 항목 비율 (너비/높이). 필요에 따라 조정
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => _handlePostClick(post.postId!), // 게시글 클릭 시 상세 페이지 이동
          child: Card(
            clipBehavior: Clip.antiAlias, // 이미지 모서리 둥글게
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: post.getImageUrl() != "$baseUrl/picture/display/default-image.jpg" // 이미지 URL 확인
                      ? Image.network(
                    post.getImageUrl(), // Post 모델의 getImageUrl 사용
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40), // 오류 이미지
                  )
                      : const Center(child: Icon(Icons.image_not_supported, size: 40)), // 이미지 없음 아이콘
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? '제목 없음',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // ✅ 좋아요 아이콘 및 수 (Post 모델에 favoriteCnt, liked 필드 사용)
                          // 웹 코드의 좋아요 버튼 로직 참고
                          GestureDetector( // 좋아요 아이콘 클릭 가능하도록 GestureDetector 추가
                            onTap: () => _handleLikeToggle(post), // 좋아요 토글 함수 호출
                            child: Icon(Icons.favorite, color: post.liked == true ? Colors.redAccent : Colors.grey, size: 16), // liked 필드 사용
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.favoriteCnt?.toString() ?? '0', // favoriteCnt 필드 사용
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          // 조회수 아이콘 및 수 (Post 모델에 views 필드 사용)
                          const Icon(Icons.visibility, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            post.views?.toString() ?? '0', // views 필드 사용
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
