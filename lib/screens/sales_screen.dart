// lib/screens/sales_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/sales_service.dart';
import '../models/sale.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SalesService _service = SalesService();
  bool _loading = true;
  String? _error;
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _loading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.userId;
    final token = auth.token;
    print('▶ SalesScreen: userId = $userId, token = $token'); // 여기에 찍어 봅니다.

    if (userId == null || token == null) {
      setState(() {
        _error = '로그인이 필요합니다.';
        _loading = false;
      });
      return;
    }

    try {
      // fetchSales는 List<Sale>을 반환
      final list = await _service.fetchSales(userId, token);
      print('▶ SalesScreen: fetchSales 결과 개수 = ${list.length}');
      setState(() {
        _sales = list;
        _error = null;
      });
    } catch (e) {
      setState(() {
        // Exception이 던져지는 경우, 여기로 옵니다.
        _error = '판매 목록 불러오기 실패: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('판매 목록'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.red))
            : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    if (_sales.isEmpty) {
      return const Center(
        child: Text('판매 목록이 없습니다.', style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = _sales[index];
        return _buildSaleItem(sale);
      },
    );
  }

  Widget _buildSaleItem(Sale sale) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/sale/${sale.saleId}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.title ?? '제목 없음',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '가격: ${sale.price ?? 0}원',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
