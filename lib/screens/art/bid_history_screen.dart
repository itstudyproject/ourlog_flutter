import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // 가격 포맷팅을 위해 intl 패키지 사용
import 'dart:async'; // Timer 사용

import '../../providers/auth_provider.dart';
import '../../models/post.dart'; // Post 모델 사용
import '../../models/trade.dart'; // TradeDTO 및 Bid 모델 사용 (필요하다면)


class BidHistoryScreen extends StatefulWidget {
  const BidHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BidHistoryScreen> createState() => _BidHistoryScreenState();
}

class _BidHistoryScreenState extends State<BidHistoryScreen> {
  List<Post> _currentBids = [];
  List<Post> _wonTrades = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer; // 남은 시간 표시를 위한 타이머
  DateTime _currentTime = DateTime.now(); // 남은 시간 계산 기준 시간

  static const String baseUrl = "http://10.100.204.171:8080/ourlog";

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
    _timer?.cancel(); // 위젯 소멸 시 타이머 해제
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || token.isEmpty) {
      // 토큰이 없는 경우 로그인 페이지로 이동
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
    });

    try {
      final headers = await _getHeaders();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId; // AuthProvider에서 현재 로그인된 사용자 ID 가져오기

      if (userId == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다. 로그인이 필요합니다.');
      }

      final uri = Uri.parse('$baseUrl/profile/purchases/$userId'); // React 코드의 API 엔드포인트 사용
      debugPrint('API 요청 URL: $uri');
      debugPrint('API 요청 헤더: $headers');

      final response = await http.get(uri, headers: headers);
      debugPrint('API 응답 상태 코드: ${response.statusCode}');
      debugPrint('API 응답 본문: ${response.body}');

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
        // 백엔드 응답 구조에 맞춰 파싱 (Post.fromJson 사용)
        final List<dynamic> currentBidsJson = data['currentBids'] ?? [];
        final List<dynamic> wonTradesJson = data['wonTrades'] ?? [];

        setState(() {
          _currentBids = currentBidsJson.map((json) => Post.fromJson(json)).toList();
          _wonTrades = wonTradesJson.map((json) => Post.fromJson(json)).toList();
          _isLoading = false;
        });

        debugPrint('Fetched ${_currentBids.length} current bids and ${_wonTrades.length} won trades.');

      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('구매/입찰 목록 불러오기 실패: $e');
      setState(() {
        _errorMessage = '목록을 불러오는 데 실패했습니다: ${e.toString()}';
        _isLoading = false;
        _currentBids = [];
        _wonTrades = [];
      });
    }
  }

  // 남은 시간 계산 및 포맷팅 함수 (React 코드 로직 참고)
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
      arguments: postId.toString(), // 게시글 ID를 문자열로 전달
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
      return Scaffold(
        appBar: AppBar(title: const Text('나의 구매 및 입찰 내역')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('나의 구매 및 입찰 내역')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // 목록이 없을 때 메시지 표시 (로딩이 끝난 후)
    if (_currentBids.isEmpty && _wonTrades.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('나의 구매 및 입찰 내역')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('구매 및 입찰 내역이 없습니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 이전 페이지로 돌아가기
                },
                child: const Text('뒤로 가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 구매 및 입찰 내역'),
      ),
      body: SingleChildScrollView(
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
              shrinkWrap: true, // ListView가 Column 내에서 사용될 때 필요
              physics: const NeverScrollableScrollPhysics(), // Column 스크롤에 맡김
              itemCount: _currentBids.length,
              itemBuilder: (context, index) {
                final item = _currentBids[index];
                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId!),
                  child: Card( // React의 div.bh-item.data 역할
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
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
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

            // 낙찰된 목록 섹션
            Text(
              '낙찰된 경매',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _wonTrades.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wonTrades.length,
              itemBuilder: (context, index) {
                final item = _wonTrades[index];
                // 낙찰가격을 highestBid 또는 startPrice로 표시
                final wonPrice = item.tradeDTO?.highestBid ?? item.tradeDTO?.startPrice;
                final wonTimeString = item.tradeDTO?.lastBidTime != null
                    ? DateFormat('yyyy.MM.dd HH:mm').format(item.tradeDTO!.lastBidTime!)
                    : '시간 정보 없음';

                return GestureDetector(
                  onTap: () => _handleArtworkClick(item.postId!),
                  child: Card( // React의 div.bh-item.data.won 역할
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
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
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
                              // 다운로드 버튼 (React 코드 참고)
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
              child: Center(child: Text('낙찰된 경매가 없습니다.')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 이전 페이지로 돌아가기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('뒤로 가기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
