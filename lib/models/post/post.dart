class PictureDTO {
  final String? picId;
  final String? uuid;
  final String? picName;
  final String? path;
  final int? downloads;
  final String? tag;
  final String? originImagePath;
  final String? thumbnailImagePath;
  final String? resizedImagePath;

  PictureDTO({
    this.picId,
    this.uuid,
    this.picName,
    this.path,
    this.downloads,
    this.tag,
    this.originImagePath,
    this.thumbnailImagePath,
    this.resizedImagePath,
  });

  factory PictureDTO.fromJson(Map<String, dynamic> json) {
    return PictureDTO(
      picId: json['picId'],
      uuid: json['uuid'],
      picName: json['picName'],
      path: json['path'],
      downloads: json['downloads'],
      tag: json['tag'],
      originImagePath: json['originImagePath'],
      thumbnailImagePath: json['thumbnailImagePath'],
      resizedImagePath: json['resizedImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'picId': picId,
      'uuid': uuid,
      'picName': picName,
      'path': path,
      'downloads': downloads,
      'tag': tag,
      'originImagePath': originImagePath,
      'thumbnailImagePath': thumbnailImagePath,
      'resizedImagePath': resizedImagePath,
    };
  }
}

class UserDTO {
  final int? userId;
  final String? nickname;
  // Add other user fields if needed by backend DTO
  // final String? email;

  UserDTO({
    this.userId,
    this.nickname,
    // this.email,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      userId: json['userId'],
      nickname: json['nickname'],
      // email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      // 'email': email,
    };
  }
}

class Post {
  final int? postId;
  final int? userId;
  final UserDTO? userDTO;
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
  int? favoriteCnt;
  final dynamic tradeDTO;
  final List<dynamic>? pictureDTOList;
  final String? profileImage;
  final int? replyCnt;
  final DateTime? regDate;
  final DateTime? modDate;
  bool liked; // 현재 사용자가 좋아요를 눌렀는지 여부

  Post({
    this.postId,
    this.userId,
    this.userDTO,
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
    this.liked = false,
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
      pictureDTOList: json['pictureDTOList'] != null
          ? List<PictureDTO>.from(json['pictureDTOList'].map((x) => PictureDTO.fromJson(x)))
          : null,
      profileImage: json['profileImage'],
      replyCnt: json['replyCnt'],
      regDate: json['regDate'] != null ? DateTime.parse(json['regDate']) : null,
      modDate: json['modDate'] != null ? DateTime.parse(json['modDate']) : null,
      liked: json['liked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'title': title,
      'content': content,
      'nickname': nickname,
      'fileName': fileName,
      'boardNo': boardNo,
      'views': views,
      'tag': tag,
      'thumbnailImagePath': thumbnailImagePath,
      'originImagePath': originImagePath,
      'resizedImagePath': resizedImagePath,
      'followers': followers,
      'downloads': downloads,
      'favoriteCnt': favoriteCnt,
      'tradeDTO': tradeDTO,
      'pictureDTOList': pictureDTOList?.map((pic) => pic.toJson()).toList(),
      'profileImage': profileImage,
      'replyCnt': replyCnt,
      'regDate': regDate?.toIso8601String(),
      'modDate': modDate?.toIso8601String(),
    };
  }

  String getImageUrl() {
    const String baseUrl = "http://10.100.204.157:8080/ourlog";

    if (pictureDTOList != null && pictureDTOList!.isNotEmpty) {
      final picData = pictureDTOList![0];
      if (picData.resizedImagePath != null) {
        return "$baseUrl/picture/display/${picData.resizedImagePath}";
      } else if (picData.thumbnailImagePath != null) {
        return "$baseUrl/picture/display/${picData.thumbnailImagePath}";
      } else if (picData.originImagePath != null) {
        return "$baseUrl/picture/display/${picData.originImagePath}";
      } else if (picData.picName != null) {
        return "$baseUrl/picture/display/${picData.picName}";
      }
    }

    if (resizedImagePath != null) {
      return "$baseUrl/picture/display/$resizedImagePath";
    } else if (thumbnailImagePath != null) {
      return "$baseUrl/picture/display/$thumbnailImagePath";
    } else if (originImagePath != null) {
      if (originImagePath is String) {
        return "$baseUrl/picture/display/$originImagePath";
      } else if (originImagePath is List && originImagePath.isNotEmpty) {
        return "$baseUrl/picture/display/${originImagePath.first}";
      }
    } else if (fileName != null) {
      return "$baseUrl/picture/display/$fileName";
    }

    return "$baseUrl/picture/display/default-image.jpg";
  }

  String getTimeLeft() {
    if (tradeDTO == null || tradeDTO!['lastBidTime'] == null) {
      return "경매 정보 없음";
    }

    final end = DateTime.parse(tradeDTO!['lastBidTime']!);
    final now = DateTime.now();
    final diff = end.difference(now);

    if (diff.isNegative) {
      return "경매 종료";
    }

    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    if (diff.inMinutes < 1) {
      return "$seconds초 남음";
    } else if (diff.inHours < 1) {
      return "$minutes분 남음";
    } else if (diff.inDays < 1) {
      return "$hours시간 $minutes분 남음";
    } else {
      return "$days일 $hours시간 $minutes분 남음";
    }
  }

  bool get isEndingSoon {
    if (tradeDTO == null || tradeDTO!['lastBidTime'] == null) {
      return false;
    }

    final end = DateTime.parse(tradeDTO!['lastBidTime']!);
    final now = DateTime.now();
    final diff = end.difference(now);

    return diff.inHours <= 1 && !diff.isNegative;
  }

  bool get isEnded {
    if (tradeDTO == null || tradeDTO!['lastBidTime'] == null) {
      return false;
    }

    final end = DateTime.parse(tradeDTO!['lastBidTime']!);
    final now = DateTime.now();
    return end.isBefore(now);
  }
}
