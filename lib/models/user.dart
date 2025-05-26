class User {
  final int userId;
  final String email;
  final String nickname;
  final String? mobile;
  final List<String> roles; // 역할 리스트

  User({
    required this.userId,
    required this.email,
    required this.nickname,
    this.mobile,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['userId'] as int,
        email: json['email'] as String,
        nickname: json['nickname'] as String,
        mobile: json['mobile'] as String?,
        roles: List<String>.from(json['roleSet'] ?? []),
      );

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      if (mobile != null) 'mobile': mobile,
      'roleSet': roles,
    };
  }

  bool get isAdmin => roles.contains('ROLE_ADMIN');
}
