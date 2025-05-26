class User {
  final int userId;
  final String email;
  final String nickname;
  final String? mobile;

  User({
    required this.userId,
    required this.email,
    required this.nickname,
    this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['userId'] as int,
    email: json['email'] as String,
    nickname: json['nickname'] as String,
    mobile: json['mobile'] as String?,
  );

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      if (mobile != null) 'mobile': mobile,
    };
  }
}