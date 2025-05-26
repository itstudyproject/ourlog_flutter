class AnswerDTO {
  final int answerId;
  final int questionId;  // 질문 ID 추가
  final String contents;
  final String regDate;
  final String modDate;

  AnswerDTO({
    required this.answerId,
    required this.questionId,
    required this.contents,
    required this.regDate,
    required this.modDate,
  });

  factory AnswerDTO.fromJson(Map<String, dynamic> json) {
    return AnswerDTO(
      answerId: json['answerId'],
      questionId: json['questionId'],  // JSON에서 받아오도록
      contents: json['contents'] ?? '',
      regDate: json['regDate'] ?? '',
      modDate: json['modDate'] ?? '',
    );
  }
}
