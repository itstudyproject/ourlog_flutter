// lib/models/sale.dart

class Sale {
  final int? saleId;
  final int? userId;
  final String? title;
  final int? price;
  // 필요한 다른 필드들도 추가

  Sale({
    this.saleId,
    this.userId,
    this.title,
    this.price,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['saleId'] as int?,
      userId: json['userId'] as int?,
      title: json['title'] as String?,
      price: json['price'] as int?,
      // 추가 필드 파싱
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'userId': userId,
      'title': title,
      'price': price,
      // 추가 필드
    };
  }
}
