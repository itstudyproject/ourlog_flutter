import 'package:ourlog/models/answer.dart';
import 'package:ourlog/models/user.dart';

class Inquiry {
  final String questionId;
  String title;
  final String regDate;
  final bool answered;
  String content;
  final Answer? answer;
  final User? user;  // User 타입으로 변경, userDTO → user

  Inquiry({
    required this.questionId,
    required this.title,
    required this.regDate,
    required this.answered,
    required this.content,
    this.answer,
    this.user,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      questionId: json['questionId'].toString(),
      title: json['title'] ?? '',
      regDate: json['regDate'] ?? '',
      answered: json['answer'] != null,
      content: json['content'] ?? '',
      answer: json['answer'] != null
          ? Answer.fromJson(json['answer'])
          : null,
      user: json['userDTO'] != null
          ? User.fromJson(json['userDTO'])
          : null,
    );
  }
}
