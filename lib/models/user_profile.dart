// lib/models/user_profile.dart

import 'package:flutter/foundation.dart'; // debugPrint 사용 시 필요

// 사용자 프로필 정보 모델
// React의 UserProfileDTO에 대응
class UserProfile {
  /// 프로필 썸네일 이미지 URL
  final String thumbnailImagePath;

  /// 닉네임
  final String nickname;

  /// 팔로워 수
  final int followCnt;

  /// 팔로잉 수
  final int followingCnt;

  /// 자기소개
  final String introduction;

  final int userId;
  final String? profileImageUrl;

  UserProfile({
    required this.thumbnailImagePath,
    required this.nickname,
    required this.followCnt,
    required this.followingCnt,
    required this.introduction,
    required this.userId,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // 백엔드 응답 구조에 따라 키 값을 조정하세요.
    // 예를 들어, userId가 'id'로 올 수도 있습니다.
    final int? parsedUserId = json['userId'] is int
        ? json['userId']
        : (json['userId'] is String ? int.tryParse(json['userId']) : null);
    
    if (parsedUserId == null) {
       debugPrint('UserProfile.fromJson: Failed to parse userId from JSON: $json');
        // 유효한 userId가 없으면 기본값 또는 오류 처리
        throw FormatException('Invalid userId in JSON: ${json['userId']}');
    }

    return UserProfile(
      thumbnailImagePath: json['thumbnailImagePath'] as String? ?? '',
      nickname:           json['nickname'] as String? ?? '',
      followCnt:    (json['followCnt']    as num?)?.toInt() ?? 0,
      followingCnt: (json['followingCnt'] as num?)?.toInt() ?? 0,
      introduction:       json['introduction'] as String? ?? '',
      userId: parsedUserId,
      profileImageUrl: json['profileImageUrl'] ?? json['originImagePath'], // 백엔드 응답 키
    );
  }

  // 디버깅을 위한 toString 메서드 추가
  @override
  String toString() {
    return 'UserProfile{userId: $userId, nickname: $nickname, profileImageUrl: $profileImageUrl}';
  }
}
