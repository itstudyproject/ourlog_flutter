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
class Bid {
  final int id;
  final int postId;
  final int userId;
  final int price;
  final String bidTime;
  final String? nickname;
  final String? profileImage;

  Bid({
    required this.id,
    required this.postId,
    required this.userId,
    required this.price,
    required this.bidTime,
    this.nickname,
    this.profileImage,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] as int,
      postId: json['postId'] as int,
      userId: json['userId'] as int,
      price: json['price'] as int,
      bidTime: json['bidTime'] as String,
      nickname: json['nickname'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'price': price,
      'bidTime': bidTime,
      if (nickname != null) 'nickname': nickname,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}
