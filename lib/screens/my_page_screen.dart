// lib/screens/my_page_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ourlog/models/post.dart';        // Post 모델
import 'package:ourlog/models/trade.dart';            // TradeDTO 모델
import 'package:ourlog/services/trade_service.dart';  // TradeService.fetchSales
import 'package:ourlog/services/profile_service.dart';
import 'package:ourlog/widgets/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'art/bid_history_screen.dart'; // 이미 사용 중이셨다고 가정

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final ProfileService _service = ProfileService();
  int? _userId;
  UserProfile? _profile;
  bool _loading = true;

  // Tab 상태: 'purchase-bid', 'sale', 'my-posts', 'bookmark'
  String _activeTab = 'purchase-bid';

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
      // 에러 처리(필요하다면)
    } finally {
      if (mounted) {
        debugPrint(
          '★★★ fetchProfile 성공: thumbnail=${_profile?.thumbnailImagePath}, profileImage=${_profile?.profileImageUrl}',
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: const Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 30),
            const _SectionTitle('메뉴'),
            const SizedBox(height: 10),
            // Tab 버튼
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('구매/입찰목록', 'purchase-bid'),
                  _buildTabButton('판매목록/현황', 'sale'),
                  _buildTabButton('내 글 목록', 'my-posts'),
                  _buildTabButton('관심목록', 'bookmark'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Flexible(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _activeTab = tabName;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          _activeTab == tabName ? Theme.of(context).primaryColor : const Color(0xFF232323),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label),
      ),
    );
  }

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
        return const BidHistoryScreen();
      case 'sale':
        return _SaleTradeList(userId: _userId!);
      case 'my-posts':
        return _UserPostGrid(userId: _userId!, listType: 'my-posts');
      case 'bookmark':
        return _UserPostGrid(userId: _userId!, listType: 'bookmark');
      default:
        return const Center(child: Text('탭 오류'));
    }
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF333333),
            backgroundImage: NetworkImage(
              'http://10.100.204.189:8080' + (_profile?.thumbnailImagePath ?? ''),
              headers: {
                'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'
              },
            ) as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '팔로워: ${_profile!.followCnt}   팔로잉: ${_profile!.followingCnt}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333333),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                            _loadProfile();
                          }
                        },
                        child: const Text('프로필수정', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton('회원정보수정', '/mypage/account/edit'),
                    const SizedBox(width: 8),
                    _actionButton('회원탈퇴', '/mypage/account/delete', backgroundColor: Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, String route, {Color backgroundColor = const Color(0xFF333333)}) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onPressed: () {
          if (_userId == null) {
            Navigator.pushNamed(context, '/login');
            return;
          }
          Navigator.pushNamed(context, route, arguments: _userId!);
        },
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// --------------------------------------
/// (A) 판매 목록/현황을 표시하는 위젯
/// --------------------------------------
class _SaleTradeList extends StatefulWidget {
  final int userId;
  const _SaleTradeList({Key? key, required this.userId}) : super(key: key);

  @override
  __SaleTradeListState createState() => __SaleTradeListState();
}

class __SaleTradeListState extends State<_SaleTradeList> {
  final TradeService _tradeService = TradeService();
  bool _isLoading = true;
  List<Post> _sellingPosts = [];
  List<Post> _soldPosts = [];
  String? _errorMessage;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  static const String baseUrl = "http://10.100.204.189:8080/ourlog";

  @override
  void initState() {
    super.initState();
    _fetchUserSales();
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

  Future<void> _fetchUserSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sellingPosts = [];
      _soldPosts = [];
    });

    try {
      // TradeService.fetchSales를 호출하여 List<TradeDTO>를 받아옵니다.
      final List<TradeDTO> trades = await _tradeService.fetchSales(widget.userId);
      debugPrint('SaleTradeList: fetchSales 결과 수 = ${trades.length}');

      // (1) “판매 중인 경매”: tradeStatus == false, bidderId == userId, sellerId != userId
      final sellingList = trades.where((t) {
        return t.tradeStatus == false &&
            t.bidderId == widget.userId &&
            t.sellerId != widget.userId;
      }).map((t) {
        // TradeDTO에 postTitle, postImage 등의 필드가 없으므로 최소한의 정보만 넣습니다.
        return Post.fromJson({
          'postId': t.postId,
          'userId': t.sellerId,
          // 제목: “게시글 #<postId>”
          'title': '게시글 #${t.postId}',
          'content': null,
          'nickname': null,
          'fileName': null,
          'boardNo': 5,
          'views': 0,
          'tag': null,
          'thumbnailImagePath': null,  // 이미지가 없으므로 null
          'resizedImagePath': null,
          'originImagePath': null,
          'followers': 0,
          'downloads': 0,
          'favoriteCnt': 0,
          'profileImage': null,
          'replyCnt': 0,
          // regDate, modDate는 유의미한 값이 없다면 지금 시각을 넣어 둡니다.
          'regDate': DateTime.now().toIso8601String(),
          'modDate': DateTime.now().toIso8601String(),
          'liked': false,
          'pictureDTOList': [],

          'tradeDTO': {
            'tradeId': t.tradeId,
            'postId': t.postId,
            'sellerId': t.sellerId,
            'bidderId': t.bidderId,
            'bidderNickname': t.bidderNickname,
            'startPrice': t.startPrice,
            'highestBid': t.highestBid,
            'nowBuy': t.nowBuy,
            'tradeStatus': t.tradeStatus,
            'startBidTime': t.startBidTime?.toIso8601String(),
            'lastBidTime': t.lastBidTime?.toIso8601String(),
          },
        });
      }).toList();

      // (2) “판매 완료/유찰된 경매”: tradeStatus == true, sellerId != userId, bidderId == userId
      final soldList = trades.where((t) {
        return t.tradeStatus == true &&
            t.sellerId != widget.userId &&
            (t.bidderId == widget.userId);
      }).map((t) {
        return Post.fromJson({
          'postId': t.postId,
          'userId': t.sellerId,
          'title': '게시글 #${t.postId}',
          'content': null,
          'nickname': null,
          'fileName': null,
          'boardNo': 5,
          'views': 0,
          'tag': null,
          'thumbnailImagePath': null,
          'resizedImagePath': null,
          'originImagePath': null,
          'followers': 0,
          'downloads': 0,
          'favoriteCnt': 0,
          'profileImage': null,
          'replyCnt': 0,
          'regDate': DateTime.now().toIso8601String(),
          'modDate': DateTime.now().toIso8601String(),
          'liked': false,
          'pictureDTOList': [],

          'tradeDTO': {
            'tradeId': t.tradeId,
            'postId': t.postId,
            'sellerId': t.sellerId,
            'bidderId': t.bidderId,
            'bidderNickname': t.bidderNickname,
            'startPrice': t.startPrice,
            'highestBid': t.highestBid,
            'nowBuy': t.nowBuy,
            'tradeStatus': t.tradeStatus,
            'startBidTime': t.startBidTime?.toIso8601String(),
            'lastBidTime': t.lastBidTime?.toIso8601String(),
          },
        });
      }).toList();

      setState(() {
        _sellingPosts = sellingList;
        _soldPosts = soldList;
        _isLoading = false;
      });
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

  String _getRemainingTime(Post item) {
    if (item.tradeDTO?.lastBidTime == null || item.tradeDTO?.tradeStatus == true) {
      return '경매 종료';
    }
    final end = item.tradeDTO!.lastBidTime!;
    final diff = end.difference(_currentTime);
    if (diff.isNegative) return '경매 종료';
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    if (days > 0) {
      return '$days일 $hours시간 $minutes분 $seconds초 남음';
    } else if (hours > 0) {
      return '$hours시간 $minutes분 $seconds초 남음';
    } else if (minutes > 0) {
      return '$minutes분 $seconds초 남음';
    } else {
      return '$seconds초 남음';
    }
  }

  String _formatPrice(int? price) {
    if (price == null) return '가격 정보 없음';
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  void _handleArtworkClick(int postId) {
    Navigator.pushNamed(context, '/Art', arguments: postId.toString());
  }

  void _handleDownloadOriginal(Post item) {
    // TradeDTO에는 originImagePath가 없으므로 다운로드 기능은 미구현 상태로 둡니다.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('다운로드 기능은 구현되지 않았습니다.')),
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 판매 중인 경매
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
                final currentPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId!),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[300],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              // 기본 이미지 사용
                              '$baseUrl/picture/display/default-image.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title ?? '제목 없음',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '현재가: ${_formatPrice(currentPrice as int?)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '남은 시간: ${_getRemainingTime(item)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child:
                            const Text('판매 중', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : const Text('판매 중인 경매가 없습니다.'),
            const SizedBox(height: 32),
            // 판매 완료/유찰된 경매
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
                final finalPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                final endTimeString = item.tradeDTO?.lastBidTime != null
                    ? DateFormat('yyyy.MM.dd HH:mm').format(item.tradeDTO!.lastBidTime!)
                    : '시간 정보 없음';
                final status = item.tradeDTO?.bidderId != null ? '판매 완료' : '유찰';
                final statusColor = item.tradeDTO?.bidderId != null ? Colors.green : Colors.grey;

                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId!),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[300],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              '$baseUrl/picture/display/default-image.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title ?? '제목 없음',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.tradeDTO?.bidderId != null ? '판매가' : '최고 입찰가'}: ${_formatPrice(finalPrice as int?)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold, color: statusColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '종료 시간: $endTimeString',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(height: 8),
                              // 다운로드 버튼은 TradeDTO에 이미지 정보가 없으므로 숨깁니다.
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
    );
  }
}

/// --------------------------------------
/// (B) 내 글 / 관심목록 그리드 위젯
/// --------------------------------------
class _UserPostGrid extends StatefulWidget {
  final int userId;
  final String listType; // 'my-posts' or 'bookmark'

  const _UserPostGrid({Key? key, required this.userId, required this.listType}) : super(key: key);

  @override
  __UserPostGridState createState() => __UserPostGridState();
}

class __UserPostGridState extends State<_UserPostGrid> {
  bool _isLoading = true;
  List<Post> _posts = [];
  String? _errorMessage;

  static const String baseUrl = "http://10.100.204.189:8080/ourlog";
  static const String imageBaseUrl = "$baseUrl/picture/display/";

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void didUpdateWidget(covariant _UserPostGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listType != oldWidget.listType || widget.userId != oldWidget.userId) {
      _fetchPosts();
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      debugPrint('_UserPostGrid: 인증 토큰 없음.');
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
        endpoint = '$baseUrl/followers/getPost/${widget.userId}';
      } else if (widget.listType == 'bookmark') {
        endpoint = '$baseUrl/favorites/user/${widget.userId}';
      } else {
        setState(() {
          _errorMessage = '알 수 없는 목록 타입: ${widget.listType}';
          _isLoading = false;
        });
        return;
      }

      final uri = Uri.parse(endpoint);
      debugPrint('_UserPostGrid 요청 URL: $uri');
      debugPrint('_UserPostGrid 요청 헤더: $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('_UserPostGrid 응답 코드: ${response.statusCode}');
      debugPrint('_UserPostGrid 응답 본문: ${response.body}');

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
        final List<dynamic> jsonList = jsonDecode(response.body) ?? [];
        final fetched = jsonList.map((e) {
          return Post.fromJson(e as Map<String, dynamic>);
        }).toList();

        setState(() {
          _posts = fetched;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        debugPrint('_UserPostGrid: ${widget.listType} 목록 없음 (404)');
      } else {
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

  void _handlePostClick(int postId) {
    Navigator.pushNamed(context, '/Art', arguments: postId.toString());
  }

  Future<void> _handleLikeToggle(Post post) async {
    if (widget.userId == null || post.postId == null) {
      debugPrint("로그인이 필요하거나 게시글 정보가 없습니다.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요하거나 게시글 정보가 없습니다.')),
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
      return;
    }

    // Optimistic UI 업데이트
    setState(() {
      _posts = _posts.map((item) {
        if (item.postId == post.postId) {
          final newLiked = !(item.liked);
          final newCnt = (item.favoriteCnt ?? 0) + (newLiked ? 1 : -1);
          return Post(
            postId: item.postId,
            userId: item.userId,
            userDTO: item.userDTO,
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
            favoriteCnt: newCnt,
            tradeDTO: item.tradeDTO,
            pictureDTOList: item.pictureDTOList,
            profileImage: item.profileImage,
            replyCnt: item.replyCnt,
            regDate: item.regDate,
            modDate: item.modDate,
            liked: newLiked,
          );
        }
        return item;
      }).toList();
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

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('favoriteCount') && data.containsKey('favorited')) {
        final latestCnt = data['favoriteCount'] as int;
        final userLiked = data['favorited'] as bool;

        setState(() {
          _posts = _posts.map((item) {
            if (item.postId == post.postId) {
              // 북마크 탭에서 좋아요 해제 시 목록에서 제거
              if (widget.listType == 'bookmark' && !userLiked) {
                return null;
              }
              return Post(
                postId: item.postId,
                userId: item.userId,
                userDTO: item.userDTO,
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
                favoriteCnt: latestCnt,
                tradeDTO: item.tradeDTO,
                pictureDTOList: item.pictureDTOList,
                profileImage: item.profileImage,
                replyCnt: item.replyCnt,
                regDate: item.regDate,
                modDate: item.modDate,
                liked: userLiked,
              );
            }
            return item;
          }).where((e) => e != null).cast<Post>().toList();
        });

        debugPrint('좋아요 토글 성공: postId=${post.postId}, favorited=$userLiked, count=$latestCnt');
      } else {
        debugPrint('좋아요 API 응답 형식 오류: $data');
        _rollbackLikeToggle(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      debugPrint('좋아요 토글 실패: ${post.postId}, 오류: $e');
      _rollbackLikeToggle(post);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좋아요 처리에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  void _rollbackLikeToggle(Post post) {
    setState(() {
      _posts = _posts.map((item) {
        if (item.postId == post.postId) {
          final rolledBackLiked = !item.liked;
          final rolledBackCnt = (item.favoriteCnt ?? 0) + (rolledBackLiked ? 1 : -1);
          return Post(
            postId: item.postId,
            userId: item.userId,
            userDTO: item.userDTO,
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
            favoriteCnt: rolledBackCnt,
            tradeDTO: item.tradeDTO,
            pictureDTOList: item.pictureDTOList,
            profileImage: item.profileImage,
            replyCnt: item.replyCnt,
            regDate: item.regDate,
            modDate: item.modDate,
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
      final emptyMsg = widget.listType == 'my-posts'
          ? '작성한 게시글이 없습니다.'
          : '관심 등록된 게시글이 없습니다.';
      return Center(child: Text(emptyMsg));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.7,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => _handlePostClick(post.postId!),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: post.getImageUrl() != "$baseUrl/picture/display/default-image.jpg"
                      ? Image.network(
                    post.getImageUrl(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 40),
                  )
                      : const Center(child: Icon(Icons.image_not_supported, size: 40)),
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
                          GestureDetector(
                            onTap: () => _handleLikeToggle(post),
                            child: Icon(
                              Icons.favorite,
                              color: post.liked ? Colors.redAccent : Colors.grey,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (post.favoriteCnt ?? 0).toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.visibility, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (post.views ?? 0).toString(),
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
