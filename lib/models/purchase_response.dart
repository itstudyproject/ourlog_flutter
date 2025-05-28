import 'trade.dart';

class PurchaseResponse {
  final List<Trade> currentBids;
  final List<Trade> wonTrades;

  PurchaseResponse({
    required this.currentBids,
    required this.wonTrades,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      currentBids: (json['currentBids'] as List<dynamic>)
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList(),
      wonTrades: (json['wonTrades'] as List<dynamic>)
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}