// lib/models/post/post.dart

import 'dart:convert';

/// Picture 관련 DTO가 이전에 `PictureDTO`로 정리되어 있었으나,
/// Flutter 쪽에서는 `Picture` 클래스로 통합하여 사용합니다.
/// (서버에서 내려주는 JSON과 맞추기 위해서 필드명은 동일하게 유지합니다.)
import './picture.dart'; // 실제 경로에 맞게 조정하세요.

/// UserDTO 정의 (백엔드에서 전달되는 형태에 맞게 사용합니다).
import './trade.dart'; // TradeDTO 모델 import 추가

/// Post 모델 클래스
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

  /// 아래 세 필드 중 하나 이상에 이미지 경로 정보가 들어올 수 있음
  final String? thumbnailImagePath;
  final String? resizedImagePath;

  /// originImagePath는 보통 String (서버에서 한 개만 내려줄 때) 혹은
  /// List<String> (여러 개 내려줄 때)로 올 수 있기 때문에 dynamic으로 선언합니다.
  final dynamic originImagePath;

  final int? followers;
  final int? downloads;
  int? favoriteCnt;
  final TradeDTO? tradeDTO;

  /// pictureDTOList는 백엔드에서 내려주는 JSON 배열을 `Picture.fromJson`으로 파싱한 리스트입니다.
  /// nullable 허용. 비어 있을 수도 있고, null일 수도 있습니다.
  final List<Picture>? pictureDTOList;

  final String? profileImage;
  final int? replyCnt;
  final DateTime regDate;
  final DateTime modDate;

  /// 현재 사용자가 좋아요를 눌렀는지 여부 (Back에서 내려주지 않으면 기본 false)
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
    required this.regDate,
    required this.modDate,
    this.liked = false,
  });

  /// JSON → Post 객체 변환 팩토리
  factory Post.fromJson(Map<String, dynamic> json) {
    // pictureDTOList 파싱: null 체크 후 존재하면 Picture.fromJson으로 변환
    List<Picture>? pics;
    if (json['pictureDTOList'] != null) {
      final rawList = json['pictureDTOList'] as List<dynamic>;
      pics = rawList
          .map((e) => Picture.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // tradeDTO 파싱: null 체크 후 존재하면 TradeDTO.fromJson으로 변환
    TradeDTO? trade;
    if (json['tradeDTO'] != null) {
      trade = TradeDTO.fromJson(json['tradeDTO'] as Map<String, dynamic>);
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
      regDate: DateTime.parse(json['regDate'] as String),
      modDate: DateTime.parse(json['modDate'] as String),
      liked: json['liked'] as bool? ?? false,
    );
  }

  /// Post 객체 → JSON 변환
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
          .toList(), // Picture 모델의 toJson 호출
      'profileImage': profileImage,
      'replyCnt': replyCnt,
      'regDate': regDate?.toIso8601String(),
      'modDate': modDate?.toIso8601String(),
      'liked': liked,
    };
  }

  /// --------------------------------------
  /// (1) 서버에 저장된 이미지 중 하나를 골라 URL을 돌려주는 헬퍼 메서드
  /// --------------------------------------
  ///
  /// 서버에서 내려줄 때,
  ///  - pictureDTOList 에 값이 있으면 리스트의 첫 번째 Picture 정보를 사용
  ///  - 각 Picture 안에 resizedImagePath, thumbnailImagePath, originImagePath, picName 등이 있을 수 있다.
  ///  - 없으면 default-image.jpg를 사용
  ///
  /// 반환 예시:
  ///   "http://서버주소/ourlog/picture/display/2025/06/02/파일명.jpg"
  String getImageUrl() {
    const String baseUrl = "http://10.100.204.189:8080/ourlog";

    // 1) pictureDTOList가 있으면, 리스트[0]에서 우선 순위대로 이미지 경로 확인
    if (pictureDTOList != null && pictureDTOList!.isNotEmpty) {
      final picData = pictureDTOList![0];

      // resizedImagePath가 있으면 가장 우선
      if (picData.resizedImagePath != null &&
          picData.resizedImagePath!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.resizedImagePath}";
      }

      // thumbnailImagePath가 있으면 그 다음
      if (picData.thumbnailImagePath != null &&
          picData.thumbnailImagePath!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.thumbnailImagePath}";
      }

      // originImagePath가 String 형태로 있을 때
      if (picData.originImagePath != null) {
        // originImagePath가 String인지 확인
        if (picData.originImagePath is String &&
            (picData.originImagePath as String).isNotEmpty) {
          return "$baseUrl/picture/display/${picData.originImagePath}";
        }
        // originImagePath가 List<String> 형태인 경우, 첫 번째 원소 사용
        if (picData.originImagePath is List<dynamic> &&
            (picData.originImagePath as List).isNotEmpty) {
          return "$baseUrl/picture/display/${(picData.originImagePath as List).first}";
        }
      }

      // picName(실제 파일명)으로도 시도해 볼 수 있다면
      if (picData.picName != null && picData.picName!.isNotEmpty) {
        return "$baseUrl/picture/display/${picData.picName}";
      }
    }

    // 2) pictureDTOList가 없거나 비어있다면, Post 객체의 필드(resizedImagePath → thumbnailImagePath → originImagePath → fileName) 순서대로 확인
    if (resizedImagePath != null && resizedImagePath!.isNotEmpty) {
      return "$baseUrl/picture/display/$resizedImagePath";
    }

    if (thumbnailImagePath != null && thumbnailImagePath!.isNotEmpty) {
      return "$baseUrl/picture/display/$thumbnailImagePath";
    }

    if (originImagePath != null) {
      // originImagePath가 String이면
      if (originImagePath is String && (originImagePath as String).isNotEmpty) {
        return "$baseUrl/picture/display/$originImagePath";
      }
      // originImagePath가 List<String>이면
      if (originImagePath is List<dynamic> &&
          (originImagePath as List).isNotEmpty) {
        return "$baseUrl/picture/display/${(originImagePath as List).first}";
      }
    }

    // fileName 필드가 있으면
    if (fileName != null && fileName!.isNotEmpty) {
      return "$baseUrl/picture/display/$fileName";
    }

    // 모든 경우에 이미지가 없으면, 기본 이미지를 사용
    return "$baseUrl/picture/display/default-image.jpg";
  }

  /// --------------------------------------
  /// (2) 경매일 때 남은 시간을 찍어주는 헬퍼
  /// --------------------------------------
  ///
  /// tradeDTO에서 'lastBidTime' 키가 String 형태(ISO 8601)로 넘어온다고 가정
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

  /// --------------------------------------
  /// (3) 경매 종료 임박 여부 (1시간 이내) 여부
  /// --------------------------------------
  bool get isEndingSoon {
    if (tradeDTO?.lastBidTime == null) {
      return false;
    }

    final end = tradeDTO!.lastBidTime!;
    final now = DateTime.now();
    final diff = end.difference(now);

    return diff.inHours <= 1 && !diff.isNegative;
  }

  /// --------------------------------------
  /// (4) 경매가 이미 끝났는지 여부
  /// --------------------------------------
  bool get isEnded {
    if (tradeDTO?.lastBidTime == null) {
      return false;
    }

    final end = tradeDTO!.lastBidTime!;
    final now = DateTime.now();
    return end.isBefore(now);
  }
}

// Simple placeholder for UserDTO to resolve compiler error
class UserDTO {
  // Add fields if needed based on actual backend structure
  // For now, an empty class is sufficient to resolve the definition error.
}
