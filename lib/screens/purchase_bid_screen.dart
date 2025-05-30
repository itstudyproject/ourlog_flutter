// lib/screens/purchase_bid_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/trade_service.dart';
import '../models/purchase_response.dart';
import '../models/trade.dart';

class PurchaseBidScreen extends StatefulWidget {
  const PurchaseBidScreen({super.key});

  @override
  _PurchaseBidScreenState createState() => _PurchaseBidScreenState();
}

class _PurchaseBidScreenState extends State<PurchaseBidScreen> {
  final _service = TradeService();
  bool _loading = true;
  String? _error;
  PurchaseResponse? _data;

  // true → "구매", false → "입찰목록"
  bool _showCurrent = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      final resp = await _service.fetchPurchases(userId);
      setState(() {
        _data = resp;
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
    final buttonStyle = const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600);
    final selectedBorder = const Border(
      bottom: BorderSide(color: Color(0xFFF8C147), width: 2),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('구매/입찰목록'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 토글 버튼 Row ─────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showCurrent = true),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: _showCurrent ? selectedBorder : null,
                          ),
                          child: Text('구매', style: buttonStyle),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showCurrent = false),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: !_showCurrent ? selectedBorder : null,
                          ),
                          child: Text('입찰목록', style: buttonStyle),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── 리스트 ────────────────────────────
                Expanded(
                  child: _showCurrent
                      ? _buildList(_data!.currentBids, '구매한 작품이 없습니다.')
                      : _buildList(_data!.wonTrades, '입찰한 작품이 없습니다.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<TradeDTO> items, String emptyText) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: Colors.white70)));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (_, i) {
        final t = items[i];
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
                      RegExp(r'\B(?=(\d{3})+(?!\d))'),
                          (m) => ',',
                    )}',
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
