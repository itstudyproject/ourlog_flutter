class User {
  final int userId;
  final String email;
  final String nickname;
  final String? mobile;
  final bool isAdmin;

  User({
    required this.userId,
    required this.email,
    required this.nickname,
    this.mobile,
    required this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final roles = (json['roleSet'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    final isAdmin = roles?.contains('ADMIN') ?? false;

    return User(
      userId: json['userId'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      mobile: json['mobile'] as String?,
      isAdmin: isAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'nickname': nickname,
      if (mobile != null) 'mobile': mobile,
      'isAdmin': isAdmin,
    };
  }
}