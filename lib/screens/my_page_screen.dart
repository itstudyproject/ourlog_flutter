import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ourlog/models/post.dart';
import 'package:ourlog/models/trade.dart';
import 'package:ourlog/models/user_profile.dart';
import 'package:ourlog/providers/auth_provider.dart';
import 'package:ourlog/services/profile_service.dart';
import 'package:ourlog/widgets/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:ourlog/models/picture.dart';

import 'art/bid_history_screen.dart';

// ----------------------------
// MyPageScreen
// ----------------------------
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

  /// 현재 활성 탭: 'purchase-bid', 'sale', 'my-posts', 'bookmark'
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
      // 필요 시 에러 처리
    } finally {
      if (mounted) setState(() => _loading = false);
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
        body: Center(
          child: Text(
            '프로필을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ),
      );
    }
    return MainLayout(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 30),
            const _SectionTitle('메뉴'),
            const SizedBox(height: 10),
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
             _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabName) {
    final isActive = _activeTab == tabName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() => _activeTab = tabName);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isActive ? Theme.of(context).primaryColor : const Color(0xFF232323),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
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
    final thumbnail = _profile?.thumbnailImagePath ?? '';
    final imageUrl = 'http://10.100.204.144:8080$thumbnail';
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
              imageUrl,
              headers: {
                'Authorization':
                'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
              },
            ),
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
                      fontWeight: FontWeight.bold),
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
                          if (result == true) _loadProfile();
                        },
                        child: const Text(
                          '프로필수정',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton('회원정보수정', '/mypage/account/edit'),
                    const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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

// ----------------------------
// Section Title
// ----------------------------
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

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
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ----------------------------
// _SaleTradeList
// ----------------------------
class _SaleTradeList extends StatefulWidget {
  final int userId;
  const _SaleTradeList({Key? key, required this.userId}) : super(key: key);

  @override
  __SaleTradeListState createState() => __SaleTradeListState();
}

class __SaleTradeListState extends State<_SaleTradeList> {
  bool _isLoading = true;
  List<Post> _sellingPosts = [];
  List<Post> _soldPosts = [];
  String? _errorMessage;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  static const String baseUrl = "http://10.100.204.144:8080/ourlog";

  @override
  void initState() {
    super.initState();
    _fetchUserSales();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _currentTime = DateTime.now());
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
      final uri = Uri.parse('$baseUrl/profile/sales/${widget.userId}');
      final response = await http.get(uri, headers: headers);

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
        print("🏷️ [SaleStatus] API 요청 URL: $uri");
        print("🏷️ [SaleStatus] 응답 상태 코드: ${response.statusCode}");
        print("🏷️ [SaleStatus] 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List<dynamic>) {
          throw Exception('판매 목록 응답 형식 오류: ${decoded.runtimeType}');
        }
        final List<dynamic> rawList = decoded;

        final active = <Post>[];
        final expired = <Post>[];


        for (var element in rawList) {
          if (element is! Map<String, dynamic>) continue;
          final item = element;

          try {
            // tradeDTO 객체 직접 생성 및 파싱 (클래스 이름을 Trade -> TradeDTO로 수정)
            final tradeJson = item['tradeDTO'] as Map<String, dynamic>? ?? item; // API 응답 구조에 따라 tradeDTO가 중첩될 수도, 아닐 수도 있음
            final String? startBidRaw = tradeJson['startBidTime'] as String?;
            final String? lastBidRaw = tradeJson['lastBidTime'] as String?;
            final bool? tradeStatusBool = tradeJson['tradeStatus'] as bool?; // API 응답의 bool 값 직접 사용

            final TradeDTO? tradeDTO = TradeDTO( // Trade -> TradeDTO
                tradeId: tradeJson['tradeId'] as int,
                postId: tradeJson['postId'] as int,
                sellerId: tradeJson['sellerId'] as int,
                bidderId: tradeJson['bidderId'] as int?,
                bidderNickname: tradeJson['bidderNickname'] as String?,
                startPrice: tradeJson['startPrice'] as int,
                highestBid: tradeJson['highestBid'] as int?,
                nowBuy: tradeJson['nowBuy'] as int,
                // tradeStatus 필드가 bool 타입이므로 boolean 값을 직접 전달
                tradeStatus: tradeStatusBool ?? false, // nullable bool? 값을 non-nullable bool로 변환 (null이면 false)
                startBidTime: startBidRaw != null ? DateTime.tryParse(startBidRaw) : null, // 안전하게 파싱
                lastBidTime: lastBidRaw != null ? DateTime.tryParse(lastBidRaw) : null,   // 안전하게 파싱
            );


            // pictureDTOList 생성: Map 리스트를 Picture 객체 리스트로 변환
            List<Picture>? pictureList;
            if (item['pictureDTOList'] is List) {
               pictureList = (item['pictureDTOList'] as List)
                   .map((picJson) => Picture.fromJson(picJson as Map<String, dynamic>))
                   .toList();
            } else if (item['postImage'] != null) {
               try {
                  pictureList = [Picture(
                    picId: item['picId'] as int?, // API 응답에 picId가 있다면 사용
                    uuid: item['postImage'] as String?, // uuid와 path, imagePath에 postImage 사용
                    picName: item['postTitle'] as String? ?? 'image', // 제목 등을 picName으로 사용
                    path: item['postImage'] as String?,
                    originImagePath: item['postImage'] as String?,
                    thumbnailImagePath: item['postImage'] as String?,
                    resizedImagePath: item['postImage'] as String?,
                   )];
               } catch(e) {
                   debugPrint('Error creating Picture from postImage: $e');
               }
            }


            final postJson = <String, dynamic>{
              'postId': item['postId'] as int?,
              'userId': item['sellerId'] as int?,
              'title': item['postTitle'] as String?,
              'content': item['content'] as String? ?? '내용 없음',
              'nickname': item['sellerNickname'] as String? ?? '알 수 없음',
              'fileName': item['postImage'] as String?,
              'boardNo': item['boardNo'] as int? ?? 5,

              'thumbnailImagePath': item['thumbnailImagePath'] as String? ?? (pictureList?.firstOrNull?.thumbnailImagePath ?? item['postImage'] as String?), // firstOrNull 사용
              'resizedImagePath': item['resizedImagePath'] as String? ?? (pictureList?.firstOrNull?.resizedImagePath ?? item['postImage'] as String?), // firstOrNull 사용
              'originImagePath': item['originImagePath'] as String? ?? (pictureList?.firstOrNull?.originImagePath ?? item['postImage'] as String?), // firstOrNull 사용

              'pictureDTOList': pictureList, // Picture 객체 리스트 사용

              'views': item['views'] as int? ?? 0,
              'tag': item['tag'] as String?,
              'followers': item['followers'] as int? ?? 0,
              'downloads': item['downloads'] as int? ?? 0,
              'favoriteCnt': item['favoriteCnt'] as int? ?? 0,
              'profileImage': item['sellerProfileImage'] as String?,
              'replyCnt': item['replyCnt'] as int? ?? 0,
              'regDate': item['regDate'] != null ? DateTime.tryParse(item['regDate'] as String) : null,
              'modDate': item['modDate'] != null ? DateTime.tryParse(item['modDate'] as String) : null,

              'liked': item['liked'] as bool? ?? false, // nullable bool? 값을 non-nullable bool로 변환 (null이면 false)

              'tradeDTO': tradeDTO, // TradeDTO 객체 사용
            };

            // Post.fromJson 대신 직접 Post 객체를 생성합니다.
             final post = Post(
                postId: postJson['postId'] as int?,
                userId: postJson['userId'] as int?,
                title: postJson['title'] as String?,
                content: postJson['content'] as String?,
                nickname: postJson['nickname'] as String?,
                fileName: postJson['fileName'] as String?,
                boardNo: postJson['boardNo'] as int?,
                views: postJson['views'] as int?,
                tag: postJson['tag'] as String?,
                thumbnailImagePath: postJson['thumbnailImagePath'] as String?,
                resizedImagePath: postJson['resizedImagePath'] as String?,
                originImagePath: postJson['originImagePath'], // dynamic 타입 그대로 사용
                followers: postJson['followers'] as int?,
                downloads: postJson['downloads'] as int?,
                favoriteCnt: postJson['favoriteCnt'] as int?,
                tradeDTO: postJson['tradeDTO'] as TradeDTO?, // TradeDTO 객체로 캐스팅
                pictureDTOList: postJson['pictureDTOList'] as List<Picture>?, // Picture 리스트로 캐스팅
                profileImage: postJson['profileImage'] as String?,
                replyCnt: postJson['replyCnt'] as int?,
                regDate: postJson['regDate'] as DateTime?,
                modDate: postJson['modDate'] as DateTime?,
                liked: postJson['liked'] as bool, // non-nullable bool로 캐스팅 (postJson 생성 시 이미 null-safe 처리됨)
             );

            // Debug print: Log the generated image URL for each post after creation
            print('Fetched Post Image URL: ${post.getImageUrl()}');

            // tradeStatusBool 값을 사용하여 분기 (API 응답에 따라 false가 ACTIVE인지 true가 ACTIVE인지 확인 필요)
            // 현재 로그 기준으로 true가 완료(expired)로 보임
            if (tradeStatusBool == false) { // tradeStatus가 false일 때 active 리스트에 추가
              active.add(post);
            } else { // tradeStatus가 true일 때 expired 리스트에 추가
              expired.add(post);
            }
          } catch (e, stacktrace) { // 스택 트레이스도 함께 출력하여 디버깅 용이하게 함
            debugPrint('Error parsing post item: $e');
            debugPrint('Stacktrace: $stacktrace');
            debugPrint('Data causing error: $item');
          }
        }

        if (mounted) {
          setState(() {
            _sellingPosts = active;
            _soldPosts = expired;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _sellingPosts = [];
            _soldPosts = [];
            _isLoading = false;
          });
        }
      } else {
        // 200 또는 404 외의 상태 코드 처리
         final errorBody = response.body.isNotEmpty ? response.body : '응답 본문 없음';
         throw Exception('서버 오류: ${response.statusCode}, 응답: $errorBody');
      }
    } catch (e, stacktrace) { // 최상위 catch에서도 스택 트레이스 출력
      if (mounted) {
        setState(() {
          _errorMessage = '판매 목록 불러오기 실패: ${e.toString()}';
          _isLoading = false;
          _sellingPosts = [];
          _soldPosts = [];
        });
         debugPrint('Error fetching sales: ${e.toString()}');
         debugPrint('Stacktrace: $stacktrace');
      }
    }
  }

  String _getRemainingTime(Post item) {
    final endTime = item.tradeDTO?.lastBidTime;
    if (endTime == null || item.tradeDTO?.tradeStatus != 'ACTIVE') {
      return '경매 종료';
    }
    final diff = endTime.difference(_currentTime);
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
    return NumberFormat('#,###').format(price);
  }

  void _handleArtworkClick(int? postId) {
    if (postId == null) return;
    Navigator.pushNamed(context, '/Art', arguments: postId.toString());
  }

  void _handleDownloadOriginal(Post item) {
    final origin = item.fileName ??
        item.thumbnailImagePath ??
        ((item.originImagePath is List && (item.originImagePath as List).isNotEmpty)
            ? (item.originImagePath as List).first
            : null);
    if (origin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('다운로드할 이미지가 없습니다.')),
      );
      return;
    }
    final imageUrl = origin.startsWith('/ourlog')
        ? 'http://10.100.204.144:8080$origin'
        : '$baseUrl/picture/display/$origin';
    debugPrint('Download original image URL: $imageUrl');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('다운로드 기능 미구현: $imageUrl')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_sellingPosts.isEmpty && _soldPosts.isEmpty) {
      return const Center(child: Text('판매 내역이 없습니다.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 판매 중인 경매',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_sellingPosts.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sellingPosts.length,
              itemBuilder: (context, index) {
                final item = _sellingPosts[index];
                final currentPrice =
                    item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                            child: item.getImageUrl() !=
                                "$baseUrl/picture/display/default-image.jpg"
                                ? () {
                                    return Image.network(
                                      item.getImageUrl(),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 30),
                                    );
                                  }()
                                : const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 30)),
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
                                  '현재가: ${_formatPrice(currentPrice)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                      color:
                                      Theme.of(context).primaryColor),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('판매 중',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const Text('판매 중인 경매가 없습니다.'),
          const SizedBox(height: 32),
          Text(
            '기간 만료된 경매',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_soldPosts.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _soldPosts.length,
              itemBuilder: (context, index) {
                final item = _soldPosts[index];
                final finalPrice =
                    item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                final endTimeString = item.tradeDTO?.lastBidTime != null
                    ? DateFormat('yyyy.MM.dd HH:mm')
                    .format(item.tradeDTO!.lastBidTime!)
                    : '시간 정보 없음';
                final isSold = item.tradeDTO?.bidderId != null;
                final status = isSold ? '판매 완료' : '유찰';
                final statusColor = isSold ? Colors.green : Colors.grey;
                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                            child: item.getImageUrl() !=
                                "$baseUrl/picture/display/default-image.jpg"
                                ? () {
                                    return Image.network(
                                      item.getImageUrl(),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 30),
                                    );
                                  }()
                                : const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 30)),
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
                                  '${isSold ? '판매가' : '최고 입찰가'}: ${_formatPrice(finalPrice)}원',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(status,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(height: 8),
                              if (isSold &&
                                  item.getImageUrl() !=
                                      "$baseUrl/picture/display/default-image.jpg")
                                IconButton(
                                  onPressed: () => _handleDownloadOriginal(item),
                                  icon: const Icon(Icons.download),
                                  tooltip: '원본 이미지 다운로드',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: Colors.grey[600],
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
          else
            const Text('기간 만료된 경매가 없습니다.'),
        ],
      ),
    );
  }
}

// ----------------------------
// _UserPostGrid
// ----------------------------
class _UserPostGrid extends StatefulWidget {
  final int userId;
  final String listType; // 'my-posts' 또는 'bookmark'
  const _UserPostGrid({Key? key, required this.userId, required this.listType})
      : super(key: key);

  @override
  __UserPostGridState createState() => __UserPostGridState();
}

class __UserPostGridState extends State<_UserPostGrid> {
  bool _isLoading = true;
  List<Post> _posts = [];
  String? _errorMessage;
  static const String baseUrl = "http://10.100.204.144:8080/ourlog";

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void didUpdateWidget(covariant _UserPostGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listType != oldWidget.listType ||
        widget.userId != oldWidget.userId) {
      _fetchPosts();
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
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
      final endpoint = widget.listType == 'my-posts'
          ? '$baseUrl/followers/getPost/${widget.userId}'
          : '$baseUrl/favorites/user/${widget.userId}';
      final uri = Uri.parse(endpoint);
      final response = await http.get(uri, headers: headers);

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
        final decoded = jsonDecode(response.body);
        if (decoded is! List<dynamic>) {
          throw Exception('게시글 응답 형식 오류: ${decoded.runtimeType}');
        }
        final List<dynamic> rawList = decoded;
        final posts = <Post>[];
        for (var element in rawList) {
          if (element is! Map<String, dynamic>) continue;
          try {
            final post = Post.fromJson(element);
             // Debug print: Log the generated image URL for each post after creation
            print('Fetched User Post/Bookmark Image URL: ${post.getImageUrl()}');
            posts.add(post);
          } catch (_) {
            // 유효하지 않은 항목은 건너뜁니다.
          }
        }
        if (mounted) {
          setState(() {
            _posts = posts;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _posts = [];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${widget.listType} 목록 불러오기 실패: ${e.toString()}';
          _isLoading = false;
          _posts = [];
        });
      }
    }
  }

  void _handlePostClick(int? postId) {
    if (postId == null) return;
    Navigator.pushNamed(context, '/Art', arguments: postId.toString());
  }

  Future<void> _handleLikeToggle(Post post) async {
    if (post.postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요하거나 작품 정보가 없습니다.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    // Optimistic UI 업데이트
    setState(() {
      _posts = _posts.map((item) {
        if (item.postId == post.postId) {
          final newLiked = !(item.liked ?? false);
          final newFavoriteCnt = (item.favoriteCnt ?? 0) + (newLiked ? 1 : -1);
          // 새 Post 객체 생성
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
            favoriteCnt: newFavoriteCnt,
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
        final int latestCount = data['favoriteCount'] as int;
        final bool userLiked = data['favorited'] as bool;
        setState(() {
          _posts = _posts.where((item) {
            if (widget.listType == 'bookmark' &&
                item.postId == post.postId &&
                !userLiked) {
              return false;
            }
            return true;
          }).map((item) {
            if (item.postId == post.postId) {
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
                favoriteCnt: latestCount,
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
          }).toList();
        });
      } else {
        _rollbackLikeToggle(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('좋아요 처리에 실패했습니다 (응답 형식 오류). 다시 시도해주세요.'),
          ),
        );
      }
    } catch (_) {
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
          final rolledBackLiked = !(item.liked ?? false);
          final rolledBackCount = (item.favoriteCnt ?? 0) + (rolledBackLiked ? 1 : -1);
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
            favoriteCnt: rolledBackCount,
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    if (_posts.isEmpty) {
      final emptyMsg = widget.listType == 'my-posts'
          ? '작성한 게시글이 없습니다.'
          : '관심 등록한 게시글이 없습니다.';
      return Center(child: Text(emptyMsg));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return GestureDetector(
          onTap: () => _handlePostClick(post.postId),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: post.getImageUrl() !=
                      "$baseUrl/picture/display/default-image.jpg"
                      ? () {
                          return Image.network(
                            post.getImageUrl(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image loading failed for URL: ${post.getImageUrl()}');
                              debugPrint('Error: $error');
                              debugPrint('StackTrace: $stackTrace');
                              return const Icon(Icons.broken_image, size: 40);
                            },
                          );
                        }()
                      : const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? '제목 없음',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                              color: post.liked == true
                                  ? Colors.redAccent
                                  : Colors.grey,
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
