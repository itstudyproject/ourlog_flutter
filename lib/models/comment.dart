// lib/models/comment.dart

class Comment {
  final int replyId;
  final int postId;
  final int userId;
  final String userNickname;
  final String content;
  final String regDate;
  final String modDate;

  bool isEditing;
  String editedContent;

  Comment({
    required this.replyId,
    required this.postId,
    required this.userId,
    required this.userNickname,
    required this.content,
    required this.regDate,
    required this.modDate,
    this.isEditing = false,
    String? editedContent,
  }) : editedContent = editedContent ?? content;

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userMap = json['userDTO'] as Map<String, dynamic>? ?? {};
    final postMap = json['postDTO'] as Map<String, dynamic>? ?? {};

    return Comment(
      replyId: json['replyId'] as int,
      postId: postMap['postId'] as int,
      userId: userMap['userId'] as int,
      userNickname: (userMap['nickname'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      regDate: (json['regDate'] as String?) ?? '',
      modDate: (json['modDate'] as String?) ?? '',
    );
  }

  /// 댓글 생성 시에는 content+postDTO만 보내고, userDTO는 백엔드에서 토큰으로 채움
  Map<String, dynamic> toJsonForCreate() {
    return {
      'content': content,
      'postDTO': {'postId': postId},
    };
  }

  /// 댓글 수정 시 필요한 JSON
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'replyId': replyId,
      'content': editedContent,
      'postDTO': {'postId': postId},
    };
  }
}
