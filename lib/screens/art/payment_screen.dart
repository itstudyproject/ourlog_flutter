import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart'; // Post 모델 import
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Post? artwork; // 이전 페이지에서 전달받을 Post 객체
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedMethod = "카카오페이"; // 기본 결제 방법
  bool _agreement = false; // 구매 조건 동의

  static const String baseUrl = "http://10.100.204.189:8080/ourlog";

  @override
  void initState() {
    super.initState();
    // initState에서는 context를 직접 사용할 수 없으므로, didChangeDependencies에서 데이터를 받습니다.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Argument로 전달된 Post 객체를 받습니다.
    if (artwork == null) {
      final Post? args = ModalRoute.of(context)?.settings.arguments as Post?;
      if (args != null) {
        setState(() {
          artwork = args;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "작품 정보를 불러올 수 없습니다.";
          _isLoading = false;
        });
      }
    }
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

  // 즉시 구매 API 호출
  Future<void> _processPayment() async {
    if (artwork?.tradeDTO == null || artwork?.tradeDTO?.tradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 정보를 찾을 수 없습니다. 거래 ID가 누락되었습니다.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final headers = await _getHeaders();
      final tradeId = artwork!.tradeDTO!.tradeId;
      final uri = Uri.parse('$baseUrl/trades/$tradeId/nowBuy'); // 즉시 구매 API 엔드포인트

      debugPrint('즉시 구매 API 요청 URL: $uri');
      debugPrint('즉시 구매 API 요청 헤더: $headers');

      // 백엔드 즉시 구매 API 호출 (React 코드 참고: POST 메소드)
      final response = await http.post(
        uri,
        headers: headers,
      );

      debugPrint('즉시 구매 API 응답 상태 코드: ${response.statusCode}');
      debugPrint('즉시 구매 API 응답 본문: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) { // 2xx 코드는 성공으로 간주
        // 결제 성공
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제가 완료되었습니다!')),
        );
        // 결제 완료 후 입찰 기록 페이지로 이동
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/Art/bidhistory'); // 입찰 기록 페이지 라우트 이름 확인
        }
      } else {
        // 결제 실패 처리
        final errorText = response.body.isNotEmpty ? response.body : '알 수 없는 서버 오류';
        debugPrint('즉시 구매 실패: ${response.statusCode} - $errorText');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('즉시 구매 실패: $errorText')),
        );
      }
    } catch (e) {
      debugPrint('즉시 구매 요청 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSubmit() {
    if (!_agreement) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 조건 및 결제진행에 동의해주세요.')),
      );
      return;
    }

    // 최종 확인창 표시
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('결제 확인'),
          content: const Text('결제를 진행하시겠습니까?'),
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
                _processPayment(); // 실제 결제 처리 함수 호출
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtworkInfoSection() {
    if (artwork == null) return Container();

    // React 코드의 imageSrc 로직을 Flutter에 맞게 변환
    // Post 모델의 getImageUrl() 메서드를 사용하여 이미지 URL을 가져옵니다.
    final imageUrl = artwork!.getImageUrl();
    final price = artwork!.tradeDTO?.nowBuy ?? 0;
    final author = artwork!.nickname ?? '알 수 없는 작가';
    final title = artwork!.title ?? '제목 없음';
    final content = artwork!.content ?? '작품 설명 없음';

    // React 코드의 pictureDTOList 처리 로직을 Flutter에 맞게 구현
    // 메인 이미지는 첫 번째 이미지를 사용하거나, fileName과 일치하는 이미지를 우선 사용하도록 ArtDetail에서 이미 구현됨.
    // 여기서는 단순히 artwork.getImageUrl()을 메인 이미지로 사용하고,
    // 썸네일 목록은 pictureDTOList를 활용하여 구성합니다.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '작품 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 이미지 썸네일 (React 코드의 artwork-thumbnail 부분)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != "$baseUrl/picture/display/default-image.jpg" // 기본 이미지가 아니면 네트워크 이미지 로드
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('이미지 로드 실패: $error');
                  debugPrint('이미지 URL: $imageUrl');
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: Text('이미지 로드 실패', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.black54))),
                  );
                },
              )
                  : const Center(child: Text('이미지 없음', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.black54))), // 기본 이미지는 텍스트로 표시
            ),
            const SizedBox(width: 16),
            // 작품 세부 정보 (React 코드의 artwork-details 부분)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 작품 설명 (React 코드의 artwork-description 부분)
        const Text(
          '작품 설명',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoSection() {
    if (artwork == null) return Container();

    final price = artwork!.tradeDTO?.nowBuy ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 금액',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildPriceRow('상품금액', price),
              const Divider(color: Colors.white24, height: 24),
              // TODO: 실제 결제 방식에 따른 금액 표시 (임시로 하드코딩)
              _buildPriceRow('결제 금액 합계', price, isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.white : Colors.white70,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${price.toString().replaceAllMapped(RegExp(r'(?<!\d)(?:(?=\d{3})+(?!\d)|(?<=\d)(?=(?:\d{3})+(?!\d)))'), (m) => ',')}원',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? Colors.orange : Colors.white,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicySection() {
    // TODO: 실제 약관 내용은 API 등으로 불러오도록 수정
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '미술 작품 설명', // 또는 '약관 및 정책'
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('※ 취소 및 환불 규정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('- 작품은 치밀한 품질/포장검수 과정을 거쳐 배송됩니다.', style: TextStyle(color: Colors.white70)),
              Text('- 작품의 하자 발생 시 교환 또는 환불이 가능합니다.', style: TextStyle(color: Colors.white70)),
              Text('- 작품의 훼손/변형/분실에 대한 책임은 매수인에게 있습니다.', style: TextStyle(color: Colors.white70)),
              // 나머지 약관 내용 추가
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    // TODO: 실제 결제 수단 목록은 API 등으로 불러오도록 수정
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '결제 방법',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildPaymentMethodItem('카카오페이', 'images/kakaopay.png'), // TODO: 이미지 경로 확인
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodItem('네이버페이', 'images/naverpay.png'), // TODO: 이미지 경로 확인
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodItem('토스페이', 'images/tosspay.png'), // TODO: 이미지 경로 확인
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(String method, String imagePath) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedMethod == method ? Colors.orange.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _selectedMethod == method ? Colors.orange : Colors.white24, width: _selectedMethod == method ? 2 : 1),
        ),
        child: Image.asset(imagePath, height: 40), // 이미지 경로를 asset으로 사용
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Row(
      children: [
        Checkbox(
          value: _agreement,
          onChanged: (bool? newValue) {
            setState(() {
              _agreement = newValue ?? false;
            });
          },
          activeColor: Colors.orange,
          checkColor: Colors.white,
        ),
        const Expanded(
          child: Text(
            '구매 조건 및 결제진행에 동의합니다.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 이전 페이지로 이동 (ArtDetail)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700], // 취소 버튼 색상 (React 참고)
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('취소'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _agreement ? _handlePaymentSubmit : null, // 동의 시에만 활성화
            style: ElevatedButton.styleFrom(
              backgroundColor: _agreement ? Colors.orange : Colors.grey[700], // 결제 버튼 색상 (React 참고)
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('결제하기'),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading && artwork == null && _errorMessage == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('결제', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (artwork == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('결제', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: Text('작품 정보를 불러올 수 없습니다.', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('주문 / 결제', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildArtworkInfoSection(), // 작품 정보 섹션
              const SizedBox(height: 32),
              _buildPaymentInfoSection(), // 결제 금액 섹션
              const SizedBox(height: 32),
              _buildPolicySection(), // 약관/정책 섹션
              const SizedBox(height: 32),
              _buildPaymentMethodSection(), // 결제 방법 섹션
              const SizedBox(height: 32),
              _buildAgreementSection(), // 동의 체크박스 섹션
              const SizedBox(height: 32),
              _buildActionButtons(), // 취소/결제 버튼 섹션
            ],
          ),
        ),
      ),
    );
  }
}
