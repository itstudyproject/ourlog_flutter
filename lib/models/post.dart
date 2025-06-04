// lib/models/post/post.dart

import 'dart:convert';

import './picture.dart';
import './trade.dart';

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

  /// 서버에서 한 개만 내려오면 String, 여러 개면 List<String>으로 넘어올 수도 있으므로
  /// dynamic으로 둡니다.
  final dynamic originImagePath;

  final int? followers;
  final int? downloads;
  int? favoriteCnt;
  final TradeDTO? tradeDTO;
  final List<Picture>? pictureDTOList;

  final String? profileImage;
  final int? replyCnt;
  final DateTime? regDate;
  final DateTime? modDate;

  bool liked;

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

  /// JSON → Post 객체 변환 팩토리
  factory Post.fromJson(Map<String, dynamic> json) {
    // (1) pictureDTOList 파싱: null 체크 후 변환
    List<Picture>? pics;
    if (json['pictureDTOList'] != null) {
      final rawList = json['pictureDTOList'] as List<dynamic>;
      pics = rawList
          .map((e) => Picture.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // (2) tradeDTO 파싱: null 체크 후 변환
    TradeDTO? trade;
    if (json['tradeDTO'] != null) {
      trade = TradeDTO.fromJson(json['tradeDTO'] as Map<String, dynamic>);
    }

    // (3) regDate, modDate 파싱: 먼저 null 여부를 보고, null이 아닐 때만 parse
    DateTime? parsedReg;
    if (json['regDate'] != null) {
      // json['regDate']가 String이 아니면 예외가 날 수 있으므로 as String?으로 시도
      final raw = json['regDate'] as String?;
      if (raw != null && raw.isNotEmpty) {
        parsedReg = DateTime.tryParse(raw);
      }
    }

    DateTime? parsedMod;
    if (json['modDate'] != null) {
      final raw = json['modDate'] as String?;
      if (raw != null && raw.isNotEmpty) {
        parsedMod = DateTime.tryParse(raw);
      }
    }

    return Post(
      postId: json['postId'] as int?,
      userId: json['userId'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      nickname: json['nickname'] as String?,
      fileName: json['fileName'] as String?,
      boardNo: json['boardNo'] as int?,
      views: json['views'] as int?,
      tag: json['tag'] as String?,

      thumbnailImagePath: json['thumbnailImagePath'] as String?,
      resizedImagePath: json['resizedImagePath'] as String?,
      originImagePath: json['originImagePath'],

      followers: json['followers'] as int?,
      downloads: json['downloads'] as int?,

      favoriteCnt: json['favoriteCnt'] as int?,

      tradeDTO: trade,
      pictureDTOList: pics,

      profileImage: json['profileImage'] as String?,
      replyCnt: json['replyCnt'] as int?,

      // (4) 위에서 안전하게 파싱한 DateTime?을 그대로 넘겨줍니다.
      regDate: parsedReg,
      modDate: parsedMod,

      liked: json['liked'] as bool? ?? false,
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
      'resizedImagePath': resizedImagePath,
      'originImagePath': originImagePath,

      'followers': followers,
      'downloads': downloads,
      'favoriteCnt': favoriteCnt,

      'tradeDTO': tradeDTO?.toJson(),
      'pictureDTOList': pictureDTOList
          ?.map((pic) => pic.toJson())
          .toList(),

      'profileImage': profileImage,
      'replyCnt': replyCnt,
      'regDate': regDate?.toIso8601String(),
      'modDate': modDate?.toIso8601String(),
      'liked': liked,
    };
  }

  /// -------------------------------
  /// (1) 서버 저장 이미지 중 우선경로를 찾아 URL로 반환
  /// -------------------------------
  String getImageUrl() {
    const String baseUrl = "http://10.100.204.144:8080/ourlog";

    if (pictureDTOList != null && pictureDTOList!.isNotEmpty) {
      final picData = pictureDTOList![0];
      if (picData.resizedImagePath != null && picData.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.resizedImagePath}";
      }
      if (picData.thumbnailImagePath != null && picData.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.thumbnailImagePath}";
      }
      if (picData.originImagePath != null) {
        if (picData.originImagePath is String && (picData.originImagePath as String).isNotEmpty) {
          return "$baseUrl/picture/display/${picData.originImagePath}";
        }
        if (picData.originImagePath is List<dynamic> &&
            (picData.originImagePath as List).isNotEmpty) {
          return "$baseUrl/picture/display/${(picData.originImagePath as List).first}";
        }
      }
      if (picData.picName != null && picData.picName!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.picName}";
      }
    }

    if (resizedImagePath != null && resizedImagePath!.isNotEmpty) {
      return "$baseUrl/picture/display/$resizedImagePath";
    }
    if (thumbnailImagePath != null && thumbnailImagePath!.isNotEmpty) {
      return "$baseUrl/picture/display/$thumbnailImagePath";
    }
    if (originImagePath != null) {
      if (originImagePath is String && (originImagePath as String).isNotEmpty) {
        return "$baseUrl/picture/display/$originImagePath";
      }
      if (originImagePath is List<dynamic> && (originImagePath as List).isNotEmpty) {
        return "$baseUrl/picture/display/${(originImagePath as List).first}";
      }
    }
    if (fileName != null && fileName!.isNotEmpty) {
      return "$baseUrl/picture/display/$fileName";
    }

    return "$baseUrl/picture/display/default-image.jpg";
  }

  /// -------------------------------
  /// (2) 남은 시간 계산 (경매 전용 예시)
  /// -------------------------------
  String getTimeLeft() {
    if (tradeDTO?.lastBidTime == null) {
      return "경매 정보 없음";
    }
    final end = tradeDTO!.lastBidTime!;
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
    if (tradeDTO?.lastBidTime == null) return false;
    final end = tradeDTO!.lastBidTime!;
    final now = DateTime.now();
    final diff = end.difference(now);
    return diff.inHours <= 1 && !diff.isNegative;
  }

  bool get isEnded {
    if (tradeDTO?.lastBidTime == null) return false;
    final end = tradeDTO!.lastBidTime!;
    final now = DateTime.now();
    return end.isBefore(now);
  }
}

// UserDTO 빈 클래스 예시
class UserDTO {
  // 필요에 따라 필드를 추가하세요
}
