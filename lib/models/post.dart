class Post {
  final int? postId;
  final int? userId;
  final String? title;
  final String? content;
  final String? nickname;
  final String? fileName;
  final int? boardNo;
  final int? views;
  final String? tag;
  final String? thumbnailImagePath;
  final String? resizedImagePath;
  final dynamic originImagePath; // String or List<String>
  final int? followers;
  final int? downloads;
  final int? favoriteCnt;
  final dynamic tradeDTO;
  final List<dynamic>? pictureDTOList;
  final String? profileImage;
  final int? replyCnt;
  final String? regDate;
  final String? modDate;

  Post({
    this.postId,
    this.userId,
    this.title,
    this.content,
    this.nickname,
    this.fileName,
    this.boardNo,
    this.views,
    this.tag,
    this.thumbnailImagePath,
    this.resizedImagePath,
    this.originImagePath,
    this.followers,
    this.downloads,
    this.favoriteCnt,
    this.tradeDTO,
    this.pictureDTOList,
    this.profileImage,
    this.replyCnt,
    this.regDate,
    this.modDate,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      userId: json['userId'],
      title: json['title'],
      content: json['content'],
      nickname: json['nickname'],
      fileName: json['fileName'],
      boardNo: json['boardNo'],
      views: json['views'],
      tag: json['tag'],
      thumbnailImagePath: json['thumbnailImagePath'],
      resizedImagePath: json['resizedImagePath'],
      originImagePath: json['originImagePath'],
      followers: json['followers'],
      downloads: json['downloads'],
      favoriteCnt: json['favoriteCnt'],
      tradeDTO: json['tradeDTO'],
      pictureDTOList: json['pictureDTOList'],
      profileImage: json['profileImage'],
      replyCnt: json['replyCnt'],
      regDate: json['regDate'],
      modDate: json['modDate'],
    );
  }
}
