class Answer {
  final int answerId;
  final int? questionId; // 🔸 nullable로 변경
  final String contents;
  final String regDate;
  final String modDate;

  Answer({
    required this.answerId,
    required this.questionId,
    required this.contents,
    required this.regDate,
    required this.modDate,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answerId: json['answerId'],
      questionId: json['questionId'],
      contents: json['contents'] ?? '',
      regDate: json['regDate'] ?? '',
      modDate: json['modDate'] ?? '',
    );
  }
}
