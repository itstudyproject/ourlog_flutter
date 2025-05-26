class Trade {
  final int id;
  final String title;
  final int price;
  final String? thumbnailUrl;
  final bool tradeStatus;

  Trade({
    required this.id,
    required this.title,
    required this.price,
    this.thumbnailUrl,
    required this.tradeStatus,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      title: json['title'] as String,
      price: json['price'] as int,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tradeStatus: json['tradeStatus'] as bool,

    );
  }
}
