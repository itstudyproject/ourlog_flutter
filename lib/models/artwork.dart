class Artwork {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double startingPrice;
  final double currentBid;
  final String artist;
  final DateTime createdAt;
  final DateTime auctionEndDate;
  final List<String> categories;
  final String ownerUserId;
  final List<Bid> bids;

  Artwork({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startingPrice,
    this.currentBid = 0.0,
    required this.artist,
    required this.createdAt,
    required this.auctionEndDate,
    this.categories = const [],
    required this.ownerUserId,
    this.bids = const [],
  });

  // JSON에서 객체 생성을 위한 팩토리 메서드
  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      startingPrice: (json['startingPrice'] as num).toDouble(),
      currentBid: (json['currentBid'] as num?)?.toDouble() ?? 0.0,
      artist: json['artist'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      auctionEndDate: DateTime.parse(json['auctionEndDate'] as String),
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ownerUserId: json['ownerUserId'] as String,
      bids: (json['bids'] as List<dynamic>?)
          ?.map((e) => Bid.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startingPrice': startingPrice,
      'currentBid': currentBid,
      'artist': artist,
      'createdAt': createdAt.toIso8601String(),
      'auctionEndDate': auctionEndDate.toIso8601String(),
      'categories': categories,
      'ownerUserId': ownerUserId,
      'bids': bids.map((bid) => bid.toJson()).toList(),
    };
  }

  // 경매 상태 확인
  bool get isAuctionEnded => DateTime.now().isAfter(auctionEndDate);

  // 최고 입찰가 반환
  double get highestBid => bids.isNotEmpty
      ? bids.map((bid) => bid.amount).reduce((a, b) => a > b ? a : b)
      : startingPrice;

  // 남은 경매 시간 계산
  Duration get remainingTime => auctionEndDate.difference(DateTime.now());

  // 새 입찰 추가
  Artwork addBid(Bid newBid) {
    if (isAuctionEnded) {
      throw Exception('경매가 이미 종료되었습니다.');
    }
    
    if (newBid.amount <= currentBid) {
      throw Exception('입찰가는 현재 최고 입찰가보다 높아야 합니다.');
    }
    
    final updatedBids = [...bids, newBid];
    return copyWith(
      bids: updatedBids, 
      currentBid: newBid.amount,
    );
  }

  // 객체의 불변성을 유지하면서 속성을 수정하기 위한 복사 메서드
  Artwork copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? startingPrice,
    double? currentBid,
    String? artist,
    DateTime? createdAt,
    DateTime? auctionEndDate,
    List<String>? categories,
    String? ownerUserId,
    List<Bid>? bids,
  }) {
    return Artwork(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      startingPrice: startingPrice ?? this.startingPrice,
      currentBid: currentBid ?? this.currentBid,
      artist: artist ?? this.artist,
      createdAt: createdAt ?? this.createdAt,
      auctionEndDate: auctionEndDate ?? this.auctionEndDate,
      categories: categories ?? this.categories,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      bids: bids ?? this.bids,
    );
  }
}

// 입찰 모델
class Bid {
  final String userId;
  final String userName;
  final double amount;
  final DateTime bidTime;

  Bid({
    required this.userId,
    required this.userName,
    required this.amount,
    required this.bidTime,
  });

  // JSON에서 객체 생성을 위한 팩토리 메서드
  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      amount: (json['amount'] as num).toDouble(),
      bidTime: DateTime.parse(json['bidTime'] as String),
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'bidTime': bidTime.toIso8601String(),
    };
  }
} 