class Post {
  final int id;
  final String title;
  final String image;

  // 필요한 경우 좋아요 상태와 수를 Post에 포함할 수도 있음:
  // final bool liked;
  // final int likeCount;

  Post({
    required this.id,
    required this.title,
    required this.image,
    // this.liked = false,
    // this.likeCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      image: json['image'] ?? '',
      // liked: json['liked'] ?? false,
      // likeCount: json['likeCount'] ?? 0,
    );
  }
}

class LikeStatus {
  final bool liked;
  final int count;

  LikeStatus({
    required this.liked,
    required this.count,
  });

  factory LikeStatus.fromJson(Map<String, dynamic> json) {
    return LikeStatus(
      liked: json['liked'] ?? false,
      count: json['count'] ?? 0,
    );
  }
}