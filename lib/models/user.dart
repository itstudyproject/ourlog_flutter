class User {
  final int userId;
  final String? mobile;

  User({
    required this.userId,
    this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as int,
      mobile: json['mobile'] as String?,
    );
  }
}