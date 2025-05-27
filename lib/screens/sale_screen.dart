// lib/screens/sale_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/trade_service.dart';
import '../models/trade.dart';
import '../models/post.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _service = TradeService();
  bool _loading = true;
  String? _error;
  List<Trade>? _sales;       // 전체 판매 목록
  List<Trade>? _completed;   // 완료된 판매

  // true면 "판매 목록", false면 "판매 현황"
  bool _showPending = true;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    if (userId == null) {
      setState(() {
        _error = '로그인이 필요합니다.';
        _loading = false;
      });
      return;
    }
    try {
      final all = await _service.fetchSales(userId);
      // 예시: Trade 객체에 상태 필드를 두고, pending/completed로 나눈다고 가정
      final pending   = all.where((t) => t.tradeStatus == false).toList();
      final completed = all.where((t) => t.tradeStatus == true).toList();

      setState(() {
        _sales = pending;
        _completed = completed;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('판매 목록/현황'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 로딩/오류 처리
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    // 버튼 스타일 정의
    final buttonStyle = const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600);
    final selectedBorder = const Border(
      bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
    );

    // 상단 토글 버튼
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showPending = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: _showPending ? selectedBorder : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('판매 목록', style: buttonStyle),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showPending = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: !_showPending ? selectedBorder : null,
                  ),
                  alignment: Alignment.center,
                  child: Text('판매 현황', style: buttonStyle),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 리스트 영역
        Expanded(
          child: _buildListView(
            _showPending ? _sales! : _completed!,
            emptyText: _showPending
                ? '판매 중인 작품이 없습니다.'
                : '완료된 판매 내역이 없습니다.',
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Trade> list, {required String emptyText}) {
    if (list.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, idx) {
        final t = list[idx];

        // '판매 목록' (진행 중) 일 때는 최고 입찰가, 없으면 시작가 표시
        // '판매 현황' (완료) 일 때는 즉시 구매가 표시
        final displayPrice = _showPending
            ? (t.highestBid ?? t.startPrice) // 진행 중: 최고 입찰가 또는 시작가
            : t.nowBuy; // 완료: 즉시 구매가

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                // 임시로 Trade ID와 Post ID를 표시합니다. 실제 게시글 제목을 표시하려면 Post 데이터를 가져와야 합니다.
                child: Text(
                  'Trade ID: ${t.tradeId}, Post ID: ${t.postId}', // 게시글 제목 대신 ID 표시
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Text(
                '₩${displayPrice.toString().replaceAllMapped(
                    RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                style: const TextStyle(
                  color: Color(0xFFF8C147),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
