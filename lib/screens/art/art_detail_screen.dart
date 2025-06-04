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
  static const String baseUrl = "http://10.100.204.189:8080/ourlog";
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
            // 경매 종료 상태일 때만 최고 입찰자인지 확인 (tradeStatus 사용)
            _isSuccessfulBidder = _currentUserId != null && artwork?.tradeDTO?.bidderId == _currentUserId && artwork?.tradeDTO?.tradeStatus == true;

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

    // 백엔드 tradeStatus가 false (진행 중 또는 유찰)일 때만 타이머 시작
    if (artwork?.tradeDTO != null && !(artwork!.tradeDTO!.tradeStatus)) {
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

        // 경매 종료 시간이 지났거나 tradeStatus가 true가 되면 타이머 중지
        // 여기서는 이미 경매 종료 상태이면 타이머가 시작되지 않도록 위에서 걸러주므로 시간만 체크
        if (artwork!.isEnded) { // isEnded는 경매 시간만 체크하는 getter
             timer.cancel();
             setState(() {
                countdown = '경매 종료';
                // TODO: 경매 상태 업데이트 API 호출 로직 추가 (React 코드 참고)
                // 만약 시간은 지났는데 아직 tradeStatus가 false라면 백엔드에 종료 요청
                if (artwork!.tradeDTO!.tradeStatus == false) {
                    // 여기서 백엔드 tradeStatus를 true로 업데이트하는 API를 호출할 수 있습니다.
                    // 예: updateAuctionStatus(artwork!.tradeDTO!.tradeId, true);
                    // 다만, 이 로직은 백엔드에서 처리하는 것이 더 안전하고 일관적입니다.
                    // 백엔드 로그에서처럼 `/trades/{tradeId}/close` 엔드포인트를 호출하여 상태를 업데이트합니다.
                    // 현재는 fetchArtworkDetails()가 최신 상태를 가져오므로 별도 호출은 생략합니다.
                }
             });
           }
      });
    } else if (artwork?.tradeDTO != null && artwork!.tradeDTO!.tradeStatus) {
      // 경매가 이미 종료된 경우 (tradeStatus가 true)
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
    // artwork?.isEnded 대신 artwork?.tradeDTO?.tradeStatus 사용
    debugPrint('경매 종료 상태 (tradeStatus): ${artwork?.tradeDTO?.tradeStatus}');

    final bidAmount = int.tryParse(_bidAmountController.text);
    debugPrint('시도 입찰 금액: $bidAmount');

    // 기본적인 입찰 금액 유효성 검사
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

    // 경매가 종료되었는지 확인 (tradeStatus 사용)
    if (artwork?.tradeDTO?.tradeStatus ?? true) { // tradeStatus가 null이거나 true이면 종료로 간주
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료된 경매에는 입찰할 수 없습니다.')),
      );
      return;
    }

    // 즉시 구매가와 입찰 금액 비교 검증 (추가 또는 수정된 부분)
    final instantPurchasePrice = artwork?.tradeDTO?.nowBuy;
    // 즉시 구매가를 초과하는 입찰 방지
    if (instantPurchasePrice != null && bidAmount > instantPurchasePrice) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입찰가는 즉시 구매가(${instantPurchasePrice.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원)를 초과할 수 없습니다.')),
      );
      return;
    }
    // 즉시 구매가와 입찰 금액이 동일한지 확인하고 즉시 구매 로직으로 연결 (웹 코드 참고)
    if (instantPurchasePrice != null && bidAmount == instantPurchasePrice) {
      // 확인 대화상자 표시
      final bool confirmNowBuy = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('즉시 구매 확인'),
            content: Text('현재 지정한 입찰 금액(${bidAmount.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원)은 즉시구매가와 동일합니다.\n즉시구매 페이지로 이동하시겠습니까?'),
            actions: <Widget>[
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop(false); // 취소 결과 반환
                },
              ),
              TextButton(
                child: const Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop(true); // 확인 결과 반환
                },
              ),
            ],
          );
        },
      ) ?? false; // 대화상자 닫기 시 null 방지

      if (confirmNowBuy) {
        // 즉시 구매 로직 호출
        _handleInstantPurchase();
        _bidAmountController.clear(); // 입력 필드 초기화
         // setState를 여기서 호출하여 _isBidding 등을 false로 설정하지 않음
         // _handleInstantPurchase 내부에서 로딩 상태 등을 관리할 수 있음
        return; // 입찰 API 호출 방지
      } else {
         // 사용자가 취소를 눌렀으면 입찰 필드만 초기화하고 함수 종료
        _bidAmountController.clear();
        return;
      }
    }


    // 이전에 입찰한 적이 있는지 확인 (즉시 구매 로직 통과 후에 확인)
    final previousBidderId = artwork?.tradeDTO?.bidderId; // TradeDTO 모델 속성 접근
    if (_currentUserId != null && previousBidderId != null && previousBidderId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 최고 입찰자입니다.')),
      );
      return;
    }

    // 최소 입찰가 검증 (즉시 구매 로직 통과 후에 확인)
    final currentHighestBid = artwork?.tradeDTO?.highestBid ?? artwork?.tradeDTO?.startPrice ?? 0;
    final minBidAmount = currentHighestBid + 1000; // 최소 1000원 이상 높게
    if (bidAmount < minBidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입찰가는 현재 최고가(${currentHighestBid.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원)보다 1000원 이상 높아야 합니다.')),
      );
      return;
    }


    setState(() {
      _isBidding = true;
    });

    try {
      final headers = await _getHeaders();
      final tradeId = artwork?.tradeDTO?.tradeId;

      if (tradeId == null) {
        throw Exception('거래 정보를 찾을 수 없습니다.');
      }

      final uri = Uri.parse('$baseUrl/trades/$tradeId/bid');
      debugPrint('입찰 API 요청 URL: $uri');
      debugPrint('입찰 API 요청 헤더: $headers');
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
        //final responseBody = jsonDecode(response.body); // <-- JSON 파싱 시도 코드 (삭제 또는 주석 처리)
        //final newHighestBid = responseBody['newHighestBid']; // <-- newHighestBid 접근 코드 (삭제 또는 주석 처리)

        // 백엔드에서 반환한 문자열 메시지를 그대로 사용
        final successMessage = response.body; // <-- 응답 본문을 문자열로 직접 사용

        ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar(content: Text('입찰이 성공적으로 완료되었습니다! 새로운 최고 입찰가: ${newHighestBid?.toString().replaceAllMapped(RegExp(r'(?<!\\d)(?:(?=\\d{3})+(?!\\d)|(?<=\\d)(?=(?:\\d{3})+(?!\\d)))'), (m) => ',')}원')), // 이전 메시지 (newHighestBid 사용)
          SnackBar(content: Text(successMessage)), // <-- 백엔드에서 받은 메시지를 직접 표시
        );

        // 입찰 성공 후 상세 정보 새로고침
        // 이 호출을 통해 최신 최고 입찰가 및 경매 상태 정보가 업데이트될 것입니다.
        fetchArtworkDetails();

        // 즉시 구매가와 입찰 금액이 동일한 경우 ("EQUALS_NOW_BUY" 응답) 별도 처리가 필요하다면 여기에 추가
        if (successMessage == "EQUALS_NOW_BUY") {
           // 예를 들어, 즉시 구매 처리 완료 메시지를 보여주거나, 즉시 구매 완료 페이지로 이동 등
           debugPrint("백엔드에서 EQUALS_NOW_BUY 응답 받음");
           // 필요에 따라 추가 UI/로직 처리
        }


      } else if (response.statusCode == 403) {
        // 403 응답 처리 수정: 메시지 표시 후 페이지에 머물도록 변경
        // 비어있는 응답 본문 파싱 오류 방지
        String errorMessage = '입찰 권한이 없습니다. (서버 응답: 403)';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body); // <-- 403 응답 본문은 JSON일 수 있으므로 파싱 시도
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('403 응답 본문 파싱 실패: $e');
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
        // 기타 서버 오류 처리
        String errorMessage = '입찰 실패: 서버 오류 (${response.statusCode})';
         if (response.body.isNotEmpty) {
          // 서버가 에러 응답 시에도 JSON 형태로 메시지를 줄 수 있으므로 시도
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {
            debugPrint('기타 오류 응답 본문 파싱 실패: $e');
             errorMessage = '$errorMessage: ${response.body}'; // 파싱 실패 시 원본 본문 포함
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // 네트워크 오류 등 예외 처리
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
    // 경매가 종료되었으면 즉시 구매할 수 없습니다. (tradeStatus 사용)
    if (artwork?.tradeDTO?.tradeStatus ?? true) { // tradeStatus가 null이거나 true이면 종료로 간주
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료된 경매는 즉시 구매할 수 없습니다.')),
      );
      return;
    }

    // 즉시 구매가 확인 대화상자는 _placeBid에서 이미 표시되었으므로 여기서는 생략
    // 바로 PaymentScreen으로 이동합니다.

    // tradeId가 null이 아닌지 Dart 방식으로 체크
    if (artwork?.tradeDTO?.tradeId != null) {
         // PaymentScreen으로 이동하며 artwork 객체 전달
        Navigator.pushNamed(
          context,
          '/art/payment', // PaymentScreen 라우트 이름
          arguments: artwork, // Post 객체 전체를 넘김
        );
    } else {
        debugPrint('Trade ID is null, cannot navigate to payment.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제를 진행할 수 없습니다. 경매 정보가 올바르지 않습니다.')),
        );
    }
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
     if (artwork?.postId != null) {
       Navigator.pushNamed(
         context,
         '/art/register',
         arguments: {
           'postData': artwork,
           'isReregister': true,
         },
       );
     } else {
       debugPrint('재등록할 게시글 정보(postId)가 없습니다.');
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('재등록할 작품 정보를 찾을 수 없습니다.')),
       );
     }
  }


  @override
  Widget build(BuildContext context) {
    // isSeller, isSuccessfulBidder 등의 상태는 initState 또는 fetchArtworkDetails에서 설정됩니다.

    // 경매 진행 중 여부 (tradeStatus가 false일 때 진행 중 또는 유찰)
    final bool isAuctionInProgress = artwork?.tradeDTO != null && (artwork!.tradeDTO!.tradeStatus == false);
    // 경매 종료 여부 (tradeStatus가 true일 때 종료)
    final bool isAuctionEndedBasedOnStatus = artwork?.tradeDTO?.tradeStatus == true;


    // 즉시구매 버튼을 보여줄지 결정: 경매 진행 중이고 판매자가 아닐 때
    final bool showInstantPurchaseButton = isAuctionInProgress && !_isSeller && artwork?.tradeDTO?.nowBuy != null && (artwork?.tradeDTO?.nowBuy ?? 0) > 0; // TradeDTO 모델 속성 접근
    // 입찰 관련 UI를 보여줄지 결정: 경매 진행 중이고 판매자가 아닐 때
    final bool showBidSection = isAuctionInProgress && !_isSeller && artwork?.tradeDTO != null;
    // 경매 종료 후 작가와 채팅 버튼을 보여줄지 결정: 경매 종료 && 낙찰자인 경우
    final bool showChatAfterEnded = isAuctionEndedBasedOnStatus && _isSuccessfulBidder;
    // 경매 진행 중일 때 작가와 채팅 버튼을 보여줄지 결정: 경매 진행 중 && 판매자가 아닌 경우
    final bool showChatDuringAuction = isAuctionInProgress && !_isSeller;


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
              child: artwork!.getImageUrl() != "http://10.100.204.189:8080/ourlog/picture/display/default-image.jpg"
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          artwork!.getImageUrl(),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            height: 300, // 이미지 높이 조정
                            child: const Center(child: Text('이미지 로드 실패')),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              'OurLog',
                              style: TextStyle(
                                fontFamily: 'NanumSquareNeo',
                                fontSize: 48,
                                color: Colors.white.withOpacity(0.35),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
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
                                    ? 'http://10.100.204.189:8080${artwork!.profileImage!}' // 도메인 추가
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
              '등록일: ${artwork!.regDate != null ? '${artwork!.regDate!.year}-${artwork!.regDate!.month.toString().padLeft(2, '0')}-${artwork!.regDate!.day.toString().padLeft(2, '0')}' : '날짜 정보 없음'}', // 날짜 부분만 표시
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 경매 정보 표시 (tradeDTO가 있을 경우)
            if (artwork!.tradeDTO != null) ...[
              Row( // 경매 정보 제목과 새로고침 아이콘을 위한 Row 추가
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     '경매 정보',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   IconButton( // 새로고침 아이콘 버튼 추가
                     icon: Icon(Icons.refresh, color: Theme.of(context).primaryColor),
                     onPressed: fetchArtworkDetails, // 누르면 fetchArtworkDetails 호출
                   ),
                 ]
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
                      const Icon(Icons.timer, size: 20, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        // artwork.isEnded 대신 isAuctionEndedBasedOnStatus 사용
                        isAuctionEndedBasedOnStatus ? '경매 종료' : countdown, // 경매 종료 여부에 따라 텍스트 표시
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          // artwork?.isEnded == true 대신 isAuctionEndedBasedOnStatus 사용
                          color: isAuctionEndedBasedOnStatus ? Colors.red : Colors.black87,
                        ),
                      ),
                      // 경매 종료 시 낙찰자와 1:1 채팅 버튼 추가
                      if (showChatAfterEnded) ...[
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _handleChat, // 채팅 로직 연결
                          child: const Text('작가와 1:1 채팅'), // 텍스트 수정
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ]
                    ]
                ),
              ),
              const SizedBox(height: 24),

              // 입찰/구매 버튼 섹션 (showBidSection 사용)
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87), // 채팅 아이콘
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
              // artwork?.isEnded == true 대신 isAuctionEndedBasedOnStatus 사용
              if (_isSeller && isAuctionEndedBasedOnStatus)
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
