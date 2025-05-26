class User {
  final int userId;
  final String? mobile;
  final List<String> roles; // 역할 리스트 추가

  User({
    required this.userId,
    this.mobile,
    required this.roles, // 생성자에 필수로 추가
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int,
      mobile: json['mobile'] as String?,
      roles: List<String>.from(json['roleSet'] ?? []), // roleSet 파싱
    );
  }
  bool get isAdmin => roles.contains('ROLE_ADMIN'); // 관리자 여부 체크용 getter
}