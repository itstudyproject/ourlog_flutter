// lib/models/user_profile.dart

class UserProfile {
  /// 프로필 썸네일 이미지 URL
  final String thumbnailImagePath;

  /// 닉네임
  final String nickname;

  /// 팔로워 수
  final int followCnt;

  /// 팔로잉 수
  int followingCnt;

  /// 자기소개
  final String introduction;

  bool isFollowing;

  UserProfile({
    required this.thumbnailImagePath,
    required this.nickname,
    required this.followCnt,
    required this.followingCnt,
    required this.introduction,
    required this.isFollowing,  // 팔로우 여부
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      thumbnailImagePath: json['thumbnailImagePath'] as String? ?? '',
      nickname:           json['nickname'] as String? ?? '',
      followCnt:    (json['followCnt']    as num?)?.toInt() ?? 0,
      followingCnt: (json['followingCnt'] as num?)?.toInt() ?? 0,
      introduction:       json['introduction'] as String? ?? '',
      isFollowing: json['isFollowing'] ?? false, // 'isFollowing' 필드 추가
    );
  }
}