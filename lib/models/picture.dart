class Picture {
  final int picId;
  final String uuid; // 파일 UUID
  final String picName; // 원본 파일명
  final String path; // 파일 저장 경로
  final String? picDescribe; // 이미지 설명
  final int? downloads; // 다운로드 수
  final String? tag; // 이미지 관련 태그
  final String? originImagePath; // 원본 이미지 경로
  final String? thumbnailImagePath; // 썸네일 이미지 경로
  final String? resizedImagePath; // 리사이징된 이미지 경로
  final int? ownerId; // 이미지 소유자 ID
  final int? postId; // 이미지가 연결된 게시물 ID

  Picture({
    required this.picId,
    required this.uuid,
    required this.picName,
    required this.path,
    this.picDescribe,
    this.downloads,
    this.tag,
    this.originImagePath,
    this.thumbnailImagePath,
    this.resizedImagePath,
    this.ownerId,
    this.postId,
  });

  factory Picture.fromJson(Map<String, dynamic> json) {
    return Picture(
      picId: json['picId'],
      uuid: json['uuid'],
      picName: json['picName'],
      path: json['path'],
      picDescribe: json['picDescribe'],
      downloads: json['downloads'],
      tag: json['tag'],
      originImagePath: json['originImagePath'],
      thumbnailImagePath: json['thumbnailImagePath'],
      resizedImagePath: json['resizedImagePath'],
      ownerId: json['ownerId'],
      postId: json['postId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'picId': picId,
      'uuid': uuid,
      'picName': picName,
      'path': path,
      'picDescribe': picDescribe,
      'downloads': downloads,
      'tag': tag,
      'originImagePath': originImagePath,
      'thumbnailImagePath': thumbnailImagePath,
      'resizedImagePath': resizedImagePath,
      'ownerId': ownerId,
      'postId': postId,
    };
  }
}
