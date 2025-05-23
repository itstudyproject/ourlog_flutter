class Inquiry {
  final String questionId;
  String title;
  final String regDate;
  final bool answered;
  String content;
  final String? answer;

  Inquiry({
    required this.questionId,
    required this.title,
    required this.regDate,
    required this.answered,
    required this.content,
    this.answer,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      questionId: json['questionId']?.toString() ?? '',
      title: json['title'] ?? '',
      regDate: json['regDate'] ?? '',
      answered: json['answerDTO'] != null,
      content: json['content'] ?? '',
      answer: json['answerDTO'] != null ? (json['answerDTO']['content'] ?? '') : null,
    );
  }
}
