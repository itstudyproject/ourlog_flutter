import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart'; // Post 모델 import
import 'dart:async'; // Timer 사용을 위해 import
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    fetchArtworkDetails();
  }

  @override
  void dispose() {
    _timer?.cancel(); // 위젯 소멸 시 타이머 취소
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
        setState(() {
          countdown = artwork!.getTimeLeft();
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

  @override
  Widget build(BuildContext context) {
    // isSeller, isSuccessfulBidder 등의 상태는 로그인 상태 및 userId가 필요하며, 이는 AuthProvider 등을 통해 관리되어야 합니다.
    // 여기서는 UI 구조만 잡고 조건부 표시는 추후 구현합니다.
    final bool isSeller = false; // TODO: 로그인 유저 ID와 artwork.userId 비교하여 설정
    // final bool isSuccessfulBidder = false; // TODO: 로그인 유저 ID와 artwork.tradeDTO.bidderId 비교 및 tradeStatus 확인하여 설정
    final bool isAuctionEnded = artwork?.isEnded ?? false;

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
                                      '${artwork!.tradeDTO!['startPrice']?.toString().replaceAllMapped(RegExp(r'(?<!\d)(?:(?=\d{3})+(?!\d)|(?<=\d)(?=(?:\d{3})+(?!\d)))'), (m) => ',')}원',
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
                                        artwork!.tradeDTO!['highestBid'] != null
                                            ? '${artwork!.tradeDTO!['highestBid']?.toString().replaceAllMapped(RegExp(r'(?<!\d)(?:(?=\d{3})+(?!\d)|(?<=\d)(?=(?:\d{3})+(?!\d)))'), (m) => ',')}원'
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
                                         '${artwork!.tradeDTO!['nowBuy']?.toString().replaceAllMapped(RegExp(r'(?<!\d)(?:(?=\d{3})+(?!\d)|(?<=\d)(?=(?:\d{3})+(?!\d)))'), (m) => ',')}원',
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
                                     color: isAuctionEnded ? Colors.red : Colors.black87,
                                   ),
                                 ),
                                 // 경매 종료 시 작가와 1:1 채팅 버튼 추가 (React 코드 참고)
                                 if (isAuctionEnded) ...[
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () { /* TODO: 채팅 로직 */ },
                                      child: const Text('작가와 1:1 채팅'),
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

                           // 입찰/구매 버튼 (경매 진행 중일 때만 표시)
                           if (!isAuctionEnded) ...[
                             // 입찰 금액 입력 (React 코드 참고하여 UI 구성)
                            // TODO: 입찰 금액 입력 필드 구현
                            // TextField(...),
                           const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () { /* TODO: 입찰 로직 */ },
                                     child: const Text('입찰하기'),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                         padding: EdgeInsets.symmetric(vertical: 12),
                                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                     ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                   child: ElevatedButton(
                                    onPressed: () { /* TODO: 즉시 구매 로직 */ },
                                     child: const Text('즉시구매'),
                                     style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                       foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                         textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                     ),
                                ),
                                 ),
                              ]
                             ),
                           const SizedBox(height: 16),
                           // 작가와 1:1 채팅 버튼 (경매 진행 중일 때 표시)
                            Center(
                              child: TextButton.icon(
                                onPressed: () { /* TODO: 채팅 로직 */ },
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
                    onPressed: () { /* TODO: 목록으로 이동 로직 */ Navigator.pop(context); }, // 뒤로 가기
                    child: const Text('목록으로'),
                    style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                 const SizedBox(width: 16),
                // 경매 재등록 버튼 (판매자 && 경매 종료 시)
                 if (isSeller && isAuctionEnded) // TODO: isSeller 조건 추가
                   Expanded(
                     flex: 1,
                      child: ElevatedButton(
                        onPressed: () { /* TODO: 경매 재등록 로직 */ },
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
