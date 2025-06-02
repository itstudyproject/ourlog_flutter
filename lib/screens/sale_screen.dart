// lib/screens/sale_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/trade_service.dart';
import '../models/trade.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  _SaleScreenState createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _service = TradeService();
  bool _loading = true;
  String? _error;
  List<TradeDTO>? _sales;       // 전체 판매 목록
  List<TradeDTO>? _completed;   // 완료된 판매

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
      final pending = all.where((t) => t.tradeStatus).toList();
      final completed = all.where((t) => !t.tradeStatus).toList();

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

  Widget _buildListView(List<TradeDTO> list, {required String emptyText}) {
    if (list.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, idx) {
        final t = list[idx];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '작품 #${t.postId}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (t.bidderNickname != null)
                      Text(
                        '현재 입찰자: ${t.bidderNickname}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${(t.highestBid ?? t.startPrice).toString().replaceAllMapped(
                        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                    style: const TextStyle(
                      color: Color(0xFFF8C147),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (t.bidAmount != null)
                    Text(
                      '입찰단위: ₩${t.bidAmount.toString().replaceAllMapped(
                        RegExp(r'\B(?=(\d{3})+(?!\d))'),
                            (m) => ',',
                      )}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
