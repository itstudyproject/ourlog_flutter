class UploadResult {
  final String originImagePath;
  final String thumbnailImagePath;

  UploadResult({required this.originImagePath, required this.thumbnailImagePath});

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      originImagePath: json['originImagePath'] as String,
      thumbnailImagePath: json['thumbnailImagePath'] as String,
    );
  }
}
