class PictureDTO {
  final String uuid;
  final String picName;
  final String path;
  final int? picId;

  PictureDTO({    required this.uuid,
    required this.picName,
    required this.path,
    this.picId,
  });

  factory PictureDTO.fromJson(Map<String, dynamic> json) {
    return PictureDTO(
      uuid: json['uuid'],
      picName: json['picName'],
      path: json['path'],
      picId: json['picId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'picName': picName,
      'path': path,
      if (picId != null) 'picId': picId,
    };
  }
}

class Post {
  final int postId;
  final int? boardNo;
  final String title;
  final String content;
  final int? userId;
  final String? nickname;
  final String? regDate;
  final String? modDate;
  final String? fileName;
  final String? uuid;
  final String? path;
  final List<PictureDTO>? pictureDTOList;
  final int? views;
  final String? tag;
  final List<ReplyDTO>? replyDTOList;

  Post({
    required this.postId,
    this.boardNo,
    required this.title,
    required this.content,
    this.userId,
    this.nickname,
    this.regDate,
    this.modDate,
    this.fileName,
    this.uuid,
    this.path,
    this.pictureDTOList,
    this.views,
    this.tag,
    this.replyDTOList,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      boardNo: json['boardNo'],
      title: json['title'],
      content: json['content'] ?? '',
      userId: json['userId'],
      nickname: json['nickname'],
      regDate: json['regDate'],
      modDate: json['modDate'],
      fileName: json['fileName'],
      uuid: json['uuid'],
      path: json['path'],
      pictureDTOList: json['pictureDTOList'] != null
          ? List<PictureDTO>.from(
              json['pictureDTOList'].map((x) => PictureDTO.fromJson(x)))
          : null,
      views: json['views'],
      tag: json['tag'],
      replyDTOList: json['replyDTOList'] != null
          ? List<ReplyDTO>.from(
              json['replyDTOList'].map((x) => ReplyDTO.fromJson(x)))
          : null,
    );
  }
}

class ReplyDTO {
  final int replyId;
  final String content;
  final String regDate;
  final Map<String, dynamic> userDTO;

  ReplyDTO({
    required this.replyId,
    required this.content,
    required this.regDate,
    required this.userDTO,
  });

  factory ReplyDTO.fromJson(Map<String, dynamic> json) {
    return ReplyDTO(
      replyId: json['replyId'],
      content: json['content'],
      regDate: json['regDate'],
      userDTO: Map<String, dynamic>.from(json['userDTO']),
    );
  }
}
