// lib/models/post.dart

class Post {
  final int postId;
  final String title;
  final String artist;
  final String imagePath;
  final int favoriteCnt;

  Post({
    required this.postId,
    required this.title,
    required this.artist,
    required this.imagePath,
    required this.favoriteCnt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      imagePath: json['imagePath'] as String,
      favoriteCnt: json['favoriteCnt'] as int,
    );
  }
}
