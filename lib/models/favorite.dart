// lib/models/favorite.dart

import 'post.dart';

class Favorite {
  final int favoriteId;
  final Post post;

  Favorite({
    required this.favoriteId,
    required this.post,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favoriteId'] as int,
      post: Post.fromJson(json['postDTO'] as Map<String, dynamic>),
    );
  }
}