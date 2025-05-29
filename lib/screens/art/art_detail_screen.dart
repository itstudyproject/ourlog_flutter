import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart'; // Post 모델 import
import 'dart:async'; // Timer 사용을 위해 import
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/trade.dart'; // TradeDTO 모델 import

class ArtDetailScreen extends StatefulWidget {
  final int postId;

  const ArtDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<ArtDetailScreen> createState() => _ArtDetailScreenState();
}

class _ArtDetailScreenState extends State<ArtDetailScreen> {
  Post? artwork;
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer; // 타이머 추가
  String countdown = '경매 정보 없음'; // 카운트다운 문자열 추가
  static const String baseUrl = "http://10.100.204.171:8080/ourlog";
  final TextEditingController _bidAmountController = TextEditingController(); // 입찰 금액 입력 컨트롤러
  bool _isBidding = false; // 입찰 중 상태

  // 사용자 상태 관련 변수 추가
  int? _currentUserId;
  bool _isSeller = false;
  bool _isSuccessfulBidder = false;

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) { // 비동기로 사용자 ID 로드 후 게시글 정보 가져오기
      fetchArtworkDetails();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯 소멸 시 타이머 취소
    _bidAmountController.dispose(); // 컨트롤러 dispose
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.userId;
    debugPrint('Current User ID: $_currentUserId');
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

  Future<void> fetchArtworkDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/post/read/${widget.postId}');
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
        final data = jsonDecode(response.body);
        // 백엔드 응답 구조에 따라 postDTO 키에서 게시글 정보를 가져옴
        final postData = data['postDTO'] ?? data;

        if (postData != null) {
          setState(() {
            artwork = Post.fromJson(postData);
            isLoading = false;
            // 판매자 및 최고 입찰자 상태 업데이트
            _isSeller = _currentUserId != null && artwork?.userId == _currentUserId;
            _isSuccessfulBidder = _currentUserId != null && artwork?.tradeDTO?.bidderId == _currentUserId && artwork?.isEnded == true; // 경매 종료 상태일 때만 최고 입찰자

            debugPrint('Is Seller: $_isSeller');
            debugPrint('Is Successful Bidder: $_isSuccessfulBidder');
          });
          // 데이터 로드 성공 후 타이머 시작
          _startCountdownTimer();
        } else {
          throw Exception('잘못된 응답 형식 또는 게시글 데이터 없음');
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('아트 상세 정보 불러오기 실패: $e');
      setState(() {
        errorMessage = '상세 정보를 불러오는 데 실패했습니다: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    // 기존 타이머가 있다면 취소
    _timer?.cancel();

    if (artwork?.tradeDTO != null && !(artwork!.isEnded)) { // 경매 정보가 있고, 종료되지 않았다면 타이머 시작
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { // 위젯이 마운트 해제되면 타이머 중지
          timer.cancel();
          return;
        }
        // artwork!.getTimeLeft() 호출 시, tradeDTO가 dynamic이므로 null 체크를 안전하게 해야 함
        final timeLeft = artwork!.getTimeLeft();
        setState(() {
          countdown = timeLeft;
        });

        // 경매 종료 시간이 되었는지 다시 확인하고 상태 업데이트 (필요 시 서버와 통신)
        if (artwork!.isEnded) {
          timer.cancel();
          setState(() {
            countdown = '경매 종료';
            // TODO: 경매 상태 업데이트 API 호출 로직 추가 (React 코드 참고)
          });
        }
      });
    } else if (artwork?.tradeDTO != null && artwork!.isEnded) {
      // 경매가 이미 종료된 경우
      setState(() {
        countdown = '경매 종료';
      });
    } else {
      // 경매 정보가 없는 경우
      setState(() {
        countdown = '경매 정보 없음';
      });
    }
  }

  // 입찰 로직
  Future<void> _placeBid() async {
    if (_isBidding) return; // 이미 입찰 중이면 중복 실행 방지

    // --- 디버깅 로깅 시작 ---
    debugPrint('--- 입찰 시도 디버그 정보 ---');
    debugPrint('현재 사용자 ID: $_currentUserId');
    debugPrint('작품 판매자 ID: ${artwork?.userId}');
    debugPrint('경매 종료 상태: ${artwork?.isEnded}');

    final bidAmount = int.tryParse(_bidAmountController.text);
    debugPrint('시도 입찰 금액: $bidAmount');

    // 현재 입찰가보다 높은지 확인
    // artwork.tradeDTO가 dynamic이므로 안전하게 접근
    if (bidAmount == null || bidAmount <= 0 || bidAmount % 1000 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 입찰 금액(1,000원 단위)을 입력해주세요.')),
      );
      return;
    }

    // 현재 로그인한 사용자가 판매자인지 확인 (UI 표시 조건과 별개로 로직에서 다시 확인)
    if (_currentUserId != null && _currentUserId == artwork?.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신의 작품에는 입찰할 수 없습니다.')),
      );
      return;
    }

    // 경매가 종료되었는지 확인 (UI 표시 조건과 별개로 로직에서 다시 확인)
    if (artwork?.isEnded ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료된 경매에는 입찰할 수 없습니다.')),
      );
      return;
    }

    // 이전에 입찰한 적이 있는지 확인
    final previousBidderId = artwork?.tradeDTO?.bidderId; // TradeDTO 모델 속성 접근
    if (_currentUserId != null && previousBidderId != null && previousBidderId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 최고 입찰자입니다.')),
      );
      return;
    }


    setState(() {
      _isBidding = true;
    });

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/trades/bid');
      debugPrint('입찰 API 요청 URL: $uri');
      debugPrint('입찰 API 요청 헤더: $headers');

      // artwork.tradeDTO가 dynamic이므로 tradeId에 안전하게 접근
      final tradeId = artwork?.tradeDTO?.tradeId; // TradeDTO 모델 속성 접근

      if (tradeId == null) {
        throw Exception('거래 정보를 찾을 수 없습니다.');
      }

      debugPrint('입찰 API 요청 본문: {"tradeId": $tradeId, "bidAmount": $bidAmount}');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'tradeId': tradeId,
          'bidAmount': bidAmount,
        }),
      );

      debugPrint('입찰 API 응답 상태 코드: ${response.statusCode}');
      debugPrint('입찰 API 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final newHighestBid = responseBody['newHighestBid']; // 백엔드 응답에서 새로운 최고 입찰가 필드를 확인해야 함

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('입찰이 성공적으로 완료되었습니다! 새로운 최고 입찰가: ${newHighestBid?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원')),
        );
        fetchArtworkDetails(); // 입찰 성공 후 상세 정보 새로고침
      } else if (response.statusCode == 403) {
        // 403 응답 처리 수정: 메시지 표시 후 페이지에 머물도록 변경
        // 비어있는 응답 본문 파싱 오류 방지
        String errorMessage = '입찰 권한이 없습니다. (서버 응답: 403)';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('403 응답 본문 파싱 실패: $e');
            // 파싱 실패 시 기본 메시지 사용
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '잘못된 입찰 요청입니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        throw Exception('입찰 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('입찰 요청 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입찰 실패: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isBidding = false;
      });
      _bidAmountController.clear(); // 입찰 필드 초기화
    }
  }

  // 즉시 구매 로직
  void _handleInstantPurchase() {
    // 판매자는 즉시 구매할 수 없습니다.
    if (_isSeller) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신의 작품을 즉시 구매할 수 없습니다.')),
      );
      return;
    }
    // 경매가 종료되었으면 즉시 구매할 수 없습니다.
    if (artwork?.isEnded ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료된 경매는 즉시 구매할 수 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('즉시 구매 확인'),
          content: Text('즉시 구매가 ${artwork!.tradeDTO!.nowBuy?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원에 진행됩니다. 결제 페이지로 이동하시겠습니까?'), // TradeDTO 모델 속성 접근
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
              },
            ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
                // PaymentScreen으로 이동하며 artwork 객체 전달
                Navigator.pushNamed(
                  context,
                  '/art/payment', // PaymentScreen 라우트 이름
                  arguments: artwork, // Post 객체 전체를 넘김
                );
              },
            ),
          ],
        );
      },
    );
  }

  // 채팅 로직 (더미 함수)
  void _handleChat() {
    // TODO: 채팅 페이지 이동 또는 채팅 기능 구현
    debugPrint('작가와 1:1 채팅');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('채팅 기능은 아직 구현되지 않았습니다.')),
    );
  }

  // 경매 재등록 로직 (더미 함수)
  void _handleReregisterAuction() {
    // TODO: 경매 재등록 페이지 이동 또는 로직 구현
    debugPrint('경매 재등록');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('경매 재등록 기능은 아직 구현되지 않았습니다.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    // isSeller, isSuccessfulBidder 등의 상태는 initState 또는 fetchArtworkDetails에서 설정됩니다.
    final bool isAuctionEnded = artwork?.isEnded ?? false;
    // 즉시구매 버튼을 보여줄지 결정: 경매 진행 중이고 판매자가 아닐 때
    final bool showInstantPurchaseButton = !isAuctionEnded && !_isSeller && artwork?.tradeDTO?.nowBuy != null && (artwork?.tradeDTO?.nowBuy ?? 0) > 0; // TradeDTO 모델 속성 접근
    // 입찰 관련 UI를 보여줄지 결정: 경매 진행 중이고 판매자가 아닐 때
    final bool showBidSection = !isAuctionEnded && !_isSeller && artwork?.tradeDTO != null;
    // 경매 종료 후 작가와 채팅 버튼을 보여줄지 결정: 경매 종료 && (판매자이거나 낙찰자인 경우)
    // React 코드에서는 낙찰자만 채팅 버튼이 보임. 여기서는 낙찰자만 보이도록 구현.
    final bool showChatAfterEnded = artwork?.isEnded == true && _isSuccessfulBidder; // isAuctionEnded 대신 artwork.isEnded 사용
    // 경매 진행 중일 때 작가와 채팅 버튼을 보여줄지 결정: 경매 진행 중 && 판매자가 아닌 경우
    final bool showChatDuringAuction = !isAuctionEnded && !_isSeller;


    return Scaffold(
      appBar: AppBar(
        title: Text(artwork?.title ?? '상세 정보'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : artwork != null
          ? SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작품 이미지
            Center(
              child: artwork!.getImageUrl() != "http://10.100.204.171:8080/ourlog/picture/display/default-image.jpg"
                  ? Image.network(
                artwork!.getImageUrl(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  height: 300, // 이미지 높이 조정
                  child: const Center(child: Text('이미지 로드 실패')),
                ),
              )
                  : Container(
                color: Colors.grey[300],
                height: 300, // 이미지 높이 조정
                child: const Center(child: Text('이미지 없음')),
              ),
            ),
            const SizedBox(height: 24), // 간격 조정

            // 작가 정보 및 좋아요 버튼
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 작가 정보 (아바타, 닉네임)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: 작가 페이지 이동 로직 구현
                        // 작가(유저)의 userId를 인자로 넘겨 /profile 경로로 이동
                        if (artwork?.userId != null) {
                          Navigator.pushNamed(
                            context,
                            '/profile', // 이동할 프로필 페이지 경로
                            arguments: artwork!.userId.toString(), // 작가 ID를 인자로 전달
                          );
                        }
                      }, // 작가 페이지 이동 로직
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: artwork!.profileImage != null
                                ? NetworkImage(
                              // React 코드의 profileImage 처리 로직 참고
                                artwork!.profileImage!.startsWith('/ourlog')
                                    ? 'http://10.100.204.171:8080${artwork!.profileImage!}' // 도메인 추가
                                    : '$baseUrl/picture/display/${artwork!.profileImage!}' // imageBaseUrl 대체
                            )
                                : null,
                            child: artwork!.profileImage == null ? Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(artwork!.nickname ?? '알 수 없음', style: Theme.of(context).textTheme.titleMedium),
                              Text('일러스트레이터', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 좋아요 버튼
                  GestureDetector(
                    onTap: () { /* TODO: 좋아요 토글 로직 */ }, // 좋아요 토글 기능 연결
                    child: Row(
                        children: [
                          Text(
                            artwork!.liked ? '🧡' : '🤍',
                            style: const TextStyle(
                              fontSize: 24,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 3.0,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${artwork!.favoriteCnt ?? 0}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ]
                    ),
                  ),
                ]
            ),
            const SizedBox(height: 16),

            // 제목
            Text(
              artwork!.title ?? '제목 없음',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 등록일
            Text(
              '등록일: ${artwork!.regDate != null ? artwork!.regDate!.split('T')[0] : '날짜 정보 없음'}', // 날짜 부분만 표시
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 경매 정보 표시 (tradeDTO가 있을 경우)
            if (artwork!.tradeDTO != null) ...[
              Text(
                '경매 정보',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 시작가, 현재 입찰가, 즉시 구매가
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('시작가', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          '${artwork!.tradeDTO!.startPrice?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('현재 입찰가', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(
                          artwork!.tradeDTO!.highestBid != null
                              ? '${artwork!.tradeDTO!.highestBid?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원'
                              : '입찰 내역 없음',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('즉시 구매가', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            '${artwork!.tradeDTO!.nowBuy?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ]
                    ),
                  ]
              ),
              const SizedBox(height: 16),
              // 남은 시간 또는 경매 종료 메시지
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200], // 배경색
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                    children: [
                      Icon(Icons.timer, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        isAuctionEnded ? '경매 종료' : countdown, // 경매 종료 여부에 따라 텍스트 표시
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: artwork?.isEnded == true ? Colors.red : Colors.black87, // isAuctionEnded 대신 artwork.isEnded 사용
                        ),
                      ),
                      // 경매 종료 시 낙찰자와 1:1 채팅 버튼 추가 (React 코드 참고)
                      if (showChatAfterEnded) ...[
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _handleChat, // 채팅 로직 연결
                          child: const Text('낙찰자와 1:1 채팅'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                      ]
                    ]
                ),
              ),
              const SizedBox(height: 24),

              // 입찰/구매 버튼 섹션 (경매 진행 중, 판매자 아닐 때 표시)
              if (showBidSection) ...[
                // 입찰 금액 입력 (React 코드 참고하여 UI 구성)
                TextField(
                  controller: _bidAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '입찰 금액 (1,000원 단위)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: '현재 입찰가 + 1000원 이상', // 힌트 텍스트 추가
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isBidding ? null : _placeBid, // 입찰 중이면 버튼 비활성화
                          child: _isBidding ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,) : const Text('입찰하기'), // 로딩 인디케이터 크기 조정
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 즉시 구매 버튼 (경매 진행 중, 판매자 아닐 때, 즉시 구매가 정보가 있을 때만 표시)
                      if (showInstantPurchaseButton)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleInstantPurchase, // 즉시구매 로직 연결
                            child: const Text('즉시구매'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey, // 색상 변경 (React 참고)
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // 즉시 구매 버튼이 없는 경우, 입찰 버튼이 전체 너비를 차지하도록 조정
                      if (!showInstantPurchaseButton)
                        const Expanded(child: SizedBox.shrink()), // 빈 공간으로 채움
                    ]
                ),
                const SizedBox(height: 16),
                // 작가와 1:1 채팅 버튼 (경매 진행 중일 때, 판매자 아닐 때 표시)
                if (showChatDuringAuction)
                  Center(
                    child: TextButton.icon(
                      onPressed: _handleChat, // 채팅 로직 연결
                      icon: Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87), // 채팅 아이콘
                      label: const Text('작가와 1:1 채팅', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
              ],
              const Divider(height: 48.0), // 구분선 - const와 height를 double로 명시

              // 작품 설명
              Text(
                '작품 설명',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                artwork!.content ?? '설명 없음',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      )
          : const Center(child: Text('게시글 정보를 불러올 수 없습니다.')),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); }, // 뒤로 가기
                  child: const Text('목록으로'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 경매 재등록 버튼 (판매자 && 경매 종료 시)
              if (_isSeller && artwork?.isEnded == true) // 판매자이고 경매 종료 시 재등록 버튼 표시 (isAuctionEnded 대신 artwork.isEnded 사용)
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _handleReregisterAuction, // 경매 재등록 로직 연결
                    child: const Text('경매 재등록'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
