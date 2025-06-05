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
    const String baseUrl = "http://10.100.204.144:8080";
    const String imageEndpoint = "/ourlog/picture/display"; // display 뒤에 슬래시 제거 (조합 시 추가)

    String? rawPath;

    // 1. thumbnailImagePath 또는 resizedImagePath에 완전한 상대 경로가 담겨 있다면 최우선 사용
    // (판매 목록/구매 목록 API 응답 형태를 고려)
    if (thumbnailImagePath != null && thumbnailImagePath!.startsWith('/')) {
       rawPath = thumbnailImagePath;
    } else if (resizedImagePath != null && resizedImagePath!.startsWith('/')) {
       rawPath = resizedImagePath;
    } else if (originImagePath != null && originImagePath is String && originImagePath.startsWith('/')) {
       rawPath = originImagePath as String;
    }
     // fileName도 완전한 상대 경로일 가능성을 고려 (UUID만 있는 경우도 있으므로 startsWith로 구분)
     else if (fileName != null && fileName!.startsWith('/')) {
       rawPath = fileName;
    }


    // 2. pictureDTOList에서 경로를 찾는 로직
    // (내 글 목록/관심 목록 API 응답 형태를 고려)
    if (rawPath == null || rawPath.isEmpty) {
      if (pictureDTOList != null && pictureDTOList!.isNotEmpty) {
        final picData = pictureDTOList![0];
        // pictureDTOList 내 Picture 객체의 필드를 확인하여 경로 조합
        if (picData.path != null && picData.path!.isNotEmpty && picData.uuid != null && picData.picName != null) {
           // "path/uuid_picName" 형태의 순수 상대 경로 조합
           rawPath = "${picData.path}/${picData.uuid}_${picData.picName}";
        } else if (picData.resizedImagePath != null && picData.resizedImagePath!.isNotEmpty && !picData.resizedImagePath!.startsWith('/')) {
           rawPath = picData.resizedImagePath; // '/'로 시작하지 않는 순수 상대 경로라고 가정
        } else if (picData.thumbnailImagePath != null && picData.thumbnailImagePath!.isNotEmpty && !picData.thumbnailImagePath!.startsWith('/')) {
           rawPath = picData.thumbnailImagePath; // '/'로 시작하지 않는 순수 상대 경로라고 가정
        } else if (picData.originImagePath != null && picData.originImagePath is String && (picData.originImagePath as String).isNotEmpty && !(picData.originImagePath as String).startsWith('/')) {
           rawPath = picData.originImagePath as String; // '/'로 시작하지 않는 순수 상대 경로라고 가정
        }
         // pictureDTOList 내 필드에 완전한 상대 경로가 담겨오는 경우도 있을 수 있음
         // 이 경우 해당 경로가 '/'로 시작할 것이므로 1번 로직에서 걸러져야 함.
      }
    }

    // 3. 최종적으로 얻은 경로를 정제하여 Base URL과 조합
    if (rawPath != null && rawPath.isNotEmpty) {
       // 경로가 이미 Base URL 뒤에 바로 붙여서 사용 가능한 완전한 상대 경로인 경우 (예: /ourlog/picture/display/...)
       if (rawPath.startsWith('/')) {
           // '/'로 시작하면 Base URL 뒤에 바로 붙임
           // (이 경우는 1번 로직에서 이미 처리되었어야 함. 혹시 빠진 경우를 위한 안전 장치)
           return "$baseUrl$rawPath";
       } else {
           // '/'로 시작하지 않는 순수한 상대 경로인 경우 (예: 2025/06/04/m_...)
           // Base URL + Endpoint + '/' + 순수한 상대 경로 조합
           String cleanPath = rawPath.replaceAll('//', '/'); // 혹시 모를 이중 슬래시 제거
           return "$baseUrl$imageEndpoint/$cleanPath"; // Endpoint 뒤에 슬래시 추가하여 조합
       }
    }

    // 모든 경로를 찾지 못한 경우 기본 이미지 반환
    return "$baseUrl$imageEndpoint/default-image.jpg"; // Endpoint 뒤에 슬래시 추가하여 조합
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
