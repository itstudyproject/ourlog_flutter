class Trade {
  final int tradeId;
  final int postId;
  final int sellerId;
  final int? bidderId; // 현재 최고 입찰자 ID
  final String? bidderNickname; // 현재 최고 입찰자 닉네임
  final int startPrice;
  final int? highestBid; // 현재 최고 입찰가
  final int? bidAmount; // 입찰 단위
  final int nowBuy;
  final bool tradeStatus; // 경매 상태 (true: 진행 중, false: 종료)
  final DateTime? startBidTime; // 경매 시작 시간
  final DateTime? lastBidTime; // 경매 종료 시간

  Trade({
    required this.tradeId,
    required this.postId,
    required this.sellerId,
    this.bidderId,
    this.bidderNickname,
    required this.startPrice,
    this.highestBid,
    this.bidAmount,
    required this.nowBuy,
    required this.tradeStatus,
    this.startBidTime,
    this.lastBidTime,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      tradeId: json['tradeId'],
      postId: json['postId'],
      sellerId: json['sellerId'],
      bidderId: json['bidderId'],
      bidderNickname: json['bidderNickname'],
      startPrice: json['startPrice'],
      highestBid: json['highestBid'],
      bidAmount: json['bidAmount'],
      nowBuy: json['nowBuy'],
      tradeStatus: json['tradeStatus'],
      startBidTime: json['startBidTime'] != null ? DateTime.parse(json['startBidTime']) : null,
      lastBidTime: json['lastBidTime'] != null ? DateTime.parse(json['lastBidTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tradeId': tradeId,
      'postId': postId,
      'sellerId': sellerId,
      'bidderId': bidderId,
      'bidderNickname': bidderNickname,
      'startPrice': startPrice,
      'highestBid': highestBid,
      'bidAmount': bidAmount,
      'nowBuy': nowBuy,
      'tradeStatus': tradeStatus,
      'startBidTime': startBidTime?.toIso8601String(),
      'lastBidTime': lastBidTime?.toIso8601String(),
    };
  }
}