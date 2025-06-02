class Picture {

  final int? picId;
  final String? uuid;
  final String? picName;
  final String? path;

  /// picDescribe : (선택) 이미지 설명
  /// downloads   : (선택) 다운로드 수
  /// tag         : (선택) 이미지 관련 태그
  final String? picDescribe;
  final int? downloads;
  final String? tag;

  /// originImagePath     : (업로드 직후 서버가 반환) 원본 이미지 상대 경로 (예: "2025/06/02/abcdef.jpg")
  /// thumbnailImagePath  : (업로드 직후 서버가 반환) 썸네일 이미지 상대 경로 (예: "2025/06/02/thumb_abcdef.jpg")
  final String? originImagePath;
  final String? thumbnailImagePath;

  /// resizedImagePath : (옵션) 리사이징된 이미지 상대 경로
  /// ownerId          : (옵션) 이 이미지의 소유자(user_id)
  /// postId           : (옵션) 이 이미지가 연결된 게시물(post_id)
  final String? resizedImagePath;
  final int? ownerId;
  final int? postId;

  /// -----------------------
  /// 생성자(constructor)
  /// -----------------------
  /// 모든 필드를 nullable로 선언했기 때문에, 업로드 직후에는 originImagePath와 thumbnailImagePath만
  /// 값을 가지고 있더라도 나머지는 null로 들어갑니다.
  Picture({
    this.picId,
    this.uuid,
    this.picName,
    this.path,
    this.picDescribe,
    this.downloads,
    this.tag,
    this.originImagePath,
    this.thumbnailImagePath,
    this.resizedImagePath,
    this.ownerId,
    this.postId,
  });

  /// -----------------------
  /// JSON → Picture 객체 변환 팩토리
  /// -----------------------
  /// 서버가 돌려주는 JSON(Map<String, dynamic>)에서 각 키를 읽어서 Picture 인스턴스를 만듭니다.
  /// JSON에 해당 키가 없거나 null인 경우에는 그대로 null로 처리합니다.
  factory Picture.fromJson(Map<String, dynamic> json) {
    return Picture(
      // int 필드들은 json[...] 이 null이 아닐 때만 int로 캐스팅
      picId: json['picId'] != null ? (json['picId'] as int) : null,
      uuid: json['uuid'] as String?,
      picName: json['picName'] as String?,
      path: json['path'] as String?,
      picDescribe: json['picDescribe'] as String?,
      downloads: json['downloads'] != null ? (json['downloads'] as int) : null,
      tag: json['tag'] as String?,
      originImagePath: json['originImagePath'] as String?,
      thumbnailImagePath: json['thumbnailImagePath'] as String?,
      resizedImagePath: json['resizedImagePath'] as String?,
      ownerId: json['ownerId'] != null ? (json['ownerId'] as int) : null,
      postId: json['postId'] != null ? (json['postId'] as int) : null,
    );
  }

  /// -----------------------
  /// Picture 객체 → JSON 변환
  /// -----------------------
  /// 서버에 PUT/POST 요청 시 사용할 때, null인 필드는 Map에 null로 포함시킵니다.
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
