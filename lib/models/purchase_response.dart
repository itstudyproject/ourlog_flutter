import 'trade.dart';

class PurchaseResponse {
  final List<TradeDTO> currentBids;
  final List<TradeDTO> wonTrades;

  PurchaseResponse({
    required this.currentBids,
    required this.wonTrades,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      currentBids: (json['currentBids'] as List<dynamic>)
          .map((e) => TradeDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      wonTrades: (json['wonTrades'] as List<dynamic>)
          .map((e) => TradeDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
