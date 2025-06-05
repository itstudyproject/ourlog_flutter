import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 가격 포맷팅을 위해 intl 패키지 사용
import 'dart:async'; // Timer 사용

import '../../providers/auth_provider.dart';
import '../../models/post.dart';      // Post 모델 사용
import '../../models/trade.dart';     // TradeDTO 모델 사용
import '../../models/picture.dart';   // Picture 모델 사용

class BidHistoryScreen extends StatefulWidget {
  const BidHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BidHistoryScreen> createState() => _BidHistoryScreenState();
}

class _BidHistoryScreenState extends State<BidHistoryScreen> {
  List<Post> _currentBids = [];
  List<Post> _completedTrades = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer; // 남은 시간 표시를 위한 타이머
  DateTime _currentTime = DateTime.now(); // 남은 시간 계산 기준 시간

  static const String baseUrl = "http://10.100.204.144:8080/ourlog";

  @override
  void initState() {
    super.initState();
    fetchUserTrades();

    // 남은 시간 계산을 위한 타이머 시작
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      throw Exception('인증 토큰이 없습니다.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchUserTrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentBids = [];
      _completedTrades = [];
    });

    try {
      final headers = await _getHeaders();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다. 로그인이 필요합니다.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final uri = Uri.parse('$baseUrl/profile/purchases/$userId');
      debugPrint('API 요청 URL: $uri');
      debugPrint('API 요청 헤더: $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('API 응답 상태 코드: ${response.statusCode}');
      debugPrint('API 응답 본문: ${response.body}');

      if (response.statusCode == 403) {
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
        final List<dynamic> currentBidsJson = data['currentBids'] ?? [];
        final List<dynamic> wonTradesJson = data['wonTrades'] ?? [];

        // ────────────────────────────────────────────────────────────────
        // 1) currentBids 파싱 (API 응답 구조에 맞춰 직접 Post 객체 생성)
        // ────────────────────────────────────────────────────────────────
        List<Post> tempCurrent = [];
        for (var jsonItem in currentBidsJson) {
          try {
            debugPrint('▶ [currentBids] JSON 항목: $jsonItem');

            // API 응답의 필드를 직접 사용하여 TradeDTO 생성
            final TradeDTO tradeDto = TradeDTO(
              tradeId: jsonItem['tradeId'] as int,
              postId: jsonItem['postId'] as int,
              sellerId: jsonItem['sellerId'] as int,
              bidderId: jsonItem['bidderId'] as int?,
              bidderNickname: jsonItem['bidderNickname'] as String?,
              startPrice: jsonItem['startPrice'] as int,
              highestBid: jsonItem['highestBid'] as int?,
              nowBuy: jsonItem['nowBuy'] as int,
              tradeStatus: jsonItem['tradeStatus'] as bool? ?? false, // bool? 처리
              startBidTime: jsonItem['startBidTime'] != null ? DateTime.tryParse(jsonItem['startBidTime'] as String) : null,
              lastBidTime: jsonItem['lastBidTime'] != null ? DateTime.tryParse(jsonItem['lastBidTime'] as String) : null,
              bidAmount: jsonItem['bidAmount'] as int?, // bidAmount 추가
            );

            // API 응답의 필드를 직접 사용하여 Post 객체 생성
            final Post post = Post(
              postId: jsonItem['postId'] as int,
              userId: jsonItem['sellerId'] as int, // 또는 userId 필드가 있다면 사용
              title: jsonItem['postTitle'] as String? ?? '제목 없음',
              content: jsonItem['content'] as String?, // content 필드가 있다면 사용
              nickname: jsonItem['sellerNickname'] as String?, // 또는 nickname 필드가 있다면 사용
              fileName: jsonItem['postImage'] as String?,
              boardNo: jsonItem['boardNo'] as int?, // boardNo 필드가 있다면 사용
              views: jsonItem['views'] as int?, // views 필드가 있다면 사용
              tag: jsonItem['tag'] as String?, // tag 필드가 있다면 사용
              thumbnailImagePath: jsonItem['postImage'] as String?, // postImage를 썸네일로 사용
              resizedImagePath: jsonItem['postImage'] as String?, // postImage를 리사이즈 이미지로 사용
              originImagePath: jsonItem['postImage'] as String?, // postImage를 원본 이미지로 사용
              followers: jsonItem['followers'] as int?, // followers 필드가 있다면 사용
              downloads: jsonItem['downloads'] as int?, // downloads 필드가 있다면 사용
              favoriteCnt: jsonItem['favoriteCnt'] as int?, // favoriteCnt 필드가 있다면 사용
              profileImage: jsonItem['profileImage'] as String?, // profileImage 필드가 있다면 사용
              replyCnt: jsonItem['replyCnt'] as int?, // replyCnt 필드가 있다면 사용
              regDate: jsonItem['regDate'] != null ? DateTime.tryParse(jsonItem['regDate'] as String) : null,
              modDate: jsonItem['modDate'] != null ? DateTime.tryParse(jsonItem['modDate'] as String) : null,
              liked: jsonItem['liked'] as bool? ?? false, // liked 필드가 있다면 사용
              tradeDTO: tradeDto, // 생성한 TradeDTO 객체 할당
              pictureDTOList: (jsonItem['postImage'] != null) // postImage를 Picture 리스트로 변환
                  ? [Picture(originImagePath: jsonItem['postImage'] as String)]
                  : null,
            );

            tempCurrent.add(post);
          } catch (e, stack) {
            debugPrint('【currentBids 파싱 에러】 e: $e');
            debugPrint('【currentBids 스택 트레이스】\n$stack');
            // 에러가 난 항목만 건너뛰기
          }
        }

        // ────────────────────────────────────────────────────────────────
        // 2) wonTrades 파싱 (기존 로직 유지 또는 위 currentBids처럼 수정)
        // wonTrades의 API 응답 구조가 currentBids와 동일하다면 위처럼 수정해야 합니다.
        // 현재 로그에는 wonTrades가 비어있으므로 currentBids에 맞춰 수정하는 것으로 가정합니다.
        // ────────────────────────────────────────────────────────────────
        List<Post> tempCompleted = [];
        for (var item in wonTradesJson) {
          final Map<String, dynamic> jsonItem = item as Map<String, dynamic>;
          try {
            debugPrint('▶ [wonTrades] JSON 전체 항목: $jsonItem');

             // API 응답의 필드를 직접 사용하여 TradeDTO 생성 (currentBids와 구조 동일 가정)
            final tradeDto = TradeDTO(
              tradeId: jsonItem['tradeId'] as int,
              postId: jsonItem['postId'] as int,
              sellerId: jsonItem['sellerId'] as int,
              bidderId: jsonItem['bidderId'] as int?,
              bidderNickname: jsonItem['bidderNickname'] as String?,
              startPrice: jsonItem['startPrice'] as int,
              highestBid: jsonItem['highestBid'] as int?,
              nowBuy: jsonItem['nowBuy'] as int,
              tradeStatus: jsonItem['tradeStatus'] as bool? ?? false, // bool? 처리
              startBidTime: jsonItem['startBidTime'] != null ? DateTime.tryParse(jsonItem['startBidTime'] as String) : null,
              lastBidTime: jsonItem['lastBidTime'] != null ? DateTime.tryParse(jsonItem['lastBidTime'] as String) : null,
              bidAmount: jsonItem['bidAmount'] as int?, // bidAmount 추가
            );

            // API 응답의 필드를 직접 사용하여 Post 객체 생성 (currentBids와 구조 동일 가정)
            final Post post = Post(
              postId: jsonItem['postId'] as int,
              userId: jsonItem['sellerId'] as int, // 또는 userId 필드가 있다면 사용
              title: jsonItem['postTitle'] as String? ?? '제목 없음',
              content: jsonItem['content'] as String?, // content 필드가 있다면 사용
              nickname: jsonItem['sellerNickname'] as String?, // 또는 nickname 필드가 있다면 사용
              fileName: jsonItem['postImage'] as String?,
              boardNo: jsonItem['boardNo'] as int?, // boardNo 필드가 있다면 사용
              views: jsonItem['views'] as int?, // views 필드가 있다면 사용
              tag: jsonItem['tag'] as String?, // tag 필드가 있다면 사용
              thumbnailImagePath: jsonItem['postImage'] as String?, // postImage를 썸네일로 사용
              resizedImagePath: jsonItem['postImage'] as String?, // postImage를 리사이즈 이미지로 사용
              originImagePath: jsonItem['postImage'] as String?, // postImage를 원본 이미지로 사용
              followers: jsonItem['followers'] as int?, // followers 필드가 있다면 사용
              downloads: jsonItem['downloads'] as int?, // downloads 필드가 있다면 사용
              favoriteCnt: jsonItem['favoriteCnt'] as int?, // favoriteCnt 필드가 있다면 사용
              profileImage: jsonItem['profileImage'] as String?, // profileImage 필드가 있다면 사용
              replyCnt: jsonItem['replyCnt'] as int?, // replyCnt 필드가 있다면 사용
              regDate: jsonItem['regDate'] != null ? DateTime.tryParse(jsonItem['regDate'] as String) : null,
              modDate: jsonItem['modDate'] != null ? DateTime.tryParse(jsonItem['modDate'] as String) : null,
              liked: jsonItem['liked'] as bool? ?? false, // liked 필드가 있다면 사용
              tradeDTO: tradeDto, // 생성한 TradeDTO 객체 할당
              pictureDTOList: (jsonItem['postImage'] != null) // postImage를 Picture 리스트로 변환
                  ? [Picture(originImagePath: jsonItem['postImage'] as String)]
                  : null,
            );

            tempCompleted.add(post);
          } catch (e, stack) {
            debugPrint('【wonTrades 파싱 에러】 e: $e');
            debugPrint('【wonTrades 스택 트레이스】\n$stack');
            // 에러 난 항목만 건너뛰기
          }
        }

        setState(() {
          _currentBids = tempCurrent;
          _completedTrades = tempCompleted;
          _isLoading = false;
        });

        debugPrint('Fetched currentBids: ${_currentBids.length}, completedTrades: ${_completedTrades.length}');
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = '데이터를 찾을 수 없습니다: ${response.statusCode}';
          _isLoading = false;
          _currentBids = [];
          _completedTrades = [];
        });
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('구매/입찰 목록 불러오기 실패: $e');
      debugPrint('스택 트레이스:\n$stack');
      setState(() {
        _errorMessage = '목록을 불러오는 데 실패했습니다: ${e.toString()}';
        _isLoading = false;
        _currentBids = [];
        _completedTrades = [];
      });
    }
  }
  // 남은 시간 계산 및 포맷팅 함수
  String _getRemainingTime(DateTime? endTime) {
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

  // 가격 포맷팅 (예: 100000 -> 100,000)
  String _formatPrice(int? price) {
    if (price == null) return '가격 정보 없음';
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  // 작품 상세 페이지로 이동 함수
  void _handleArtworkClick(int postId) {
    Navigator.pushNamed(
      context,
      '/Art', // ArtDetailScreen 라우트 이름
      arguments: postId.toString(),
    );
  }

  // 원본 이미지 다운로드 (더미 기능)
  void _handleDownloadOriginal(Post item) {
    // TODO: 실제 다운로드 로직 구현
    debugPrint('Download original image for postId: ${item.postId}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('원본 이미지 다운로드 기능은 아직 구현되지 않았습니다.')),
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

    // 목록이 없을 때 메시지 표시 (로딩이 끝난 후)
    if (_currentBids.isEmpty && _completedTrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('구매 및 입찰 내역이 없습니다.'),
            SizedBox(height: 16),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 입찰 중인 목록 섹션
          Text(
            '현재 입찰 중인 경매',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _currentBids.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentBids.length,
            itemBuilder: (context, index) {
              final item = _currentBids[index];
              return GestureDetector(
                onTap: () => _handleArtworkClick(item.postId!),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지 썸네일
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg"
                              ? Image.network(
                            item.getImageUrl(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          )
                              : const Center(child: Icon(Icons.image_not_supported)),
                        ),
                        const SizedBox(width: 16),
                        // 상세 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ?? '제목 없음',
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '현재가: ${_formatPrice(item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice)}원',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.getTimeLeft(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        // 상태 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('입찰 중', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
              : const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text('현재 입찰 중인 경매가 없습니다.')),
          ),

          const SizedBox(height: 32),

          // 완료된 거래 목록 섹션
          Text(
            '완료된 거래',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _completedTrades.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _completedTrades.length,
            itemBuilder: (context, index) {
              final item = _completedTrades[index];
              // 낙찰가격을 highestBid 또는 startPrice로 표시
              final wonPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
              final wonTimeString = item.tradeDTO?.lastBidTime != null
                  ? DateFormat('yyyy.MM.dd HH:mm').format(item.tradeDTO!.lastBidTime!)
                  : '시간 정보 없음';

              return GestureDetector(
                onTap: () => _handleArtworkClick(item.postId!),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지 썸네일
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg"
                              ? Image.network(
                            item.getImageUrl(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          )
                              : const Center(child: Icon(Icons.image_not_supported)),
                        ),
                        const SizedBox(width: 16),
                        // 상세 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ?? '제목 없음',
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '낙찰가: ${_formatPrice(wonPrice)}원',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '낙찰 시간: $wonTimeString',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        // 상태 및 다운로드 버튼
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('낙찰', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            const SizedBox(height: 8),
                            if (item.getImageUrl() != "$baseUrl/picture/display/default-image.jpg")
                              IconButton(
                                onPressed: () => _handleDownloadOriginal(item),
                                icon: const Icon(Icons.download),
                                tooltip: '원본 이미지 다운로드',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
              : const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text('완료된 거래가 없습니다.')),
          ),
        ],
      ),
    );
  }
}
