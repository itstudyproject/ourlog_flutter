// lib/screens/post/community_post_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/post.dart';
import '../../models/picture.dart';
import '../../models/comment.dart';
import '../../services/post_service.dart';
import '../../services/picture_service.dart';
import '../../services/comment_service.dart';
import '../../providers/auth_provider.dart';

class CommunityPostDetailScreen extends StatefulWidget {
final int postId;
const CommunityPostDetailScreen({Key? key, required this.postId}) : super(key: key);

@override
State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
Post? _post;
bool _isLoading = true;
String _errorMessage = '';
bool _isEditing = false;
bool _isPickingImage = false;

// ── 댓글 관련 상태 ─────────────────────────────────────────────
List<Comment> _comments = [];
bool _commentsLoading = true;
final TextEditingController _newCommentController = TextEditingController();
final Map<int, TextEditingController> _editCommentControllers = {};
final Map<int, bool> _isEditingComment = {};

// ── 게시글 수정 모드용 컨트롤러 ─────────────────────────────────
final TextEditingController _titleController = TextEditingController();
final TextEditingController _contentController = TextEditingController();
final TextEditingController _tagController = TextEditingController();

// ── 이미지 관련 상태 ─────────────────────────────────────────
List<Picture> _existingPictures = [];
List<File> _newAttachedImages = [];
List<Picture> _uploadedNewPictures = [];
int? _selectedThumbnailId;

@override
void initState() {
super.initState();
_fetchPostDetail();
_fetchComments();
}

@override
void dispose() {
_titleController.dispose();
_contentController.dispose();
_tagController.dispose();
_newCommentController.dispose();
_editCommentControllers.forEach((_, ctrl) => ctrl.dispose());
super.dispose();
}

/// 서버에서 게시글 상세 정보 가져오기
Future<void> _fetchPostDetail() async {
setState(() {
_isLoading = true;
_errorMessage = '';
});
try {
final fetched = await PostService.getPostById(widget.postId);
setState(() {
_post = fetched;
_isLoading = false;

// 수정 모드 진입 시 컨트롤러 초기화
_titleController.text = fetched.title ?? '';
_contentController.text = fetched.content ?? '';
_tagController.text = fetched.tag ?? '';

// 이미지 목록 복사
_existingPictures = List<Picture>.from(fetched.pictureDTOList ?? []);

// 썸네일 ID 초기화
if (fetched.thumbnailImagePath != null) {
final idx = _existingPictures.indexWhere(
(p) => p.thumbnailImagePath == fetched.thumbnailImagePath,
);
if (idx >= 0) {
_selectedThumbnailId = _existingPictures[idx].picId;
}
}
});
} catch (e) {
setState(() {
_isLoading = false;
_errorMessage = '게시글 로딩 실패: ${e.toString()}';
});
}
}

// ── 댓글 목록 불러오기 ─────────────────────────────────────────
Future<void> _fetchComments() async {
setState(() => _commentsLoading = true);
try {
final fetchedComments = await CommentService.getComments(widget.postId);
setState(() {
_comments = fetchedComments;
});
} catch (e) {
// 무시하거나 SnackBar 띄워도 됨
} finally {
setState(() => _commentsLoading = false);
}
}

/// 새 댓글 등록 (POST /reply/{postId})
Future<void> _addComment() async {
final text = _newCommentController.text.trim();
if (text.isEmpty) return;

try {
await CommentService.addComment(widget.postId, text);
_newCommentController.clear();
await _fetchComments();
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('댓글 등록 실패: ${e.toString()}')),
);
}
}

/// 댓글 수정 (PUT /reply/update/{replyId})
Future<void> _updateComment(int replyId) async {
final controller = _editCommentControllers[replyId];
if (controller == null) return;

final newText = controller.text.trim();
if (newText.isEmpty) return;

try {
final original = _comments.firstWhere((c) => c.replyId == replyId);
await CommentService.updateComment(replyId, original.postId, newText);
setState(() {
_isEditingComment[replyId] = false;
});
await _fetchComments();
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('댓글 수정 실패: ${e.toString()}')),
);
}
}

/// 댓글 삭제 (DELETE /reply/remove/{replyId})
Future<void> _deleteComment(int replyId) async {
try {
await CommentService.deleteComment(replyId);
await _fetchComments();
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('댓글 삭제 실패: ${e.toString()}')),
);
}
}

/// 수정 모드 진입
void _startEditing() {
if (_post == null) return;
setState(() {
_isEditing = true;
});
}

/// 수정 모드: 새 이미지 선택
Future<void> _pickNewImage() async {
if (_isPickingImage) return;
setState(() => _isPickingImage = true);

try {
final picker = ImagePicker();
final picked = await picker.pickMultiImage();
if (picked != null && picked.isNotEmpty) {
final existingPaths = {
..._newAttachedImages.map((f) => f.path),
..._existingPictures.map((p) => p.originImagePath ?? ''),
};
setState(() {
for (var x in picked) {
final f = File(x.path);
if (!existingPaths.contains(f.path)) {
_newAttachedImages.add(f);
}
}
});
}
} catch (e) {
print('이미지 피커 오류: $e');
} finally {
setState(() => _isPickingImage = false);
}
}

/// 수정 모드: 기존 서버 이미지 삭제
Future<void> _removeExistingPicture(Picture pic) async {
try {
await PictureService.deletePicture(pic.picId!);
setState(() {
_existingPictures.removeWhere((p) => p.picId == pic.picId);
if (_selectedThumbnailId == pic.picId) {
_selectedThumbnailId = null;
}
_post?.pictureDTOList?.removeWhere((p) => p.picId == pic.picId);
});
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('이미지가 삭제되었습니다.')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('이미지 삭제 실패: ${e.toString()}')),
);
}
}

/// 수정 모드: 로컬 이미지 업로드
Future<void> _uploadNewImagesForEdit() async {
if (_newAttachedImages.isEmpty) return;
setState(() {
_isLoading = true;
_errorMessage = '';
});
try {
for (final file in _newAttachedImages) {
final result = await PictureService.uploadImage(file);
final pic = Picture.fromJson(result);
_uploadedNewPictures.add(pic);

if (file.hashCode == _selectedThumbnailId) {
_selectedThumbnailId = pic.picId;
}
}
_newAttachedImages.clear();
} catch (e) {
setState(() {
_errorMessage = '이미지 업로드 실패: ${e.toString()}';
});
} finally {
setState(() {
_isLoading = false;
});
}
}

/// 수정 모드: 썸네일 선택
void _selectThumbnail(int id) {
setState(() {
_selectedThumbnailId = id;
});
}

/// 수정 저장
Future<void> _saveEdit() async {
if (_post == null) return;

final updatedTitle = _titleController.text.trim();
final updatedContent = _contentController.text.trim();
final updatedTag = _tagController.text.trim();

if (updatedTitle.isEmpty || updatedContent.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
);
return;
}

setState(() {
_isLoading = true;
});

try {
// 1) 로컬 이미지 업로드
await _uploadNewImagesForEdit();

// 2) 기존 + 새 이미지 합치기
final combinedPictures = <Picture>[];
combinedPictures.addAll(_existingPictures);
combinedPictures.addAll(_uploadedNewPictures);

// 3) 썸네일 경로 결정
String? newThumbnailPath;
if (_selectedThumbnailId != null) {
final selPic = combinedPictures.firstWhere(
(p) => p.picId == _selectedThumbnailId,
orElse: () => combinedPictures.first,
);
newThumbnailPath = selPic.thumbnailImagePath;
}

// 4) 수정된 Post 객체 생성
final updatedPost = Post(
postId: _post!.postId,
userId: _post!.userId,
userDTO: _post!.userDTO,
title: updatedTitle,
content: updatedContent,
nickname: _post!.nickname,
fileName: _post!.fileName,
boardNo: _post!.boardNo,
views: _post!.views,
tag: updatedTag,
thumbnailImagePath: newThumbnailPath,
resizedImagePath: _post!.resizedImagePath,
originImagePath: _post!.originImagePath,
followers: _post!.followers,
downloads: _post!.downloads,
favoriteCnt: _post!.favoriteCnt,
tradeDTO: _post!.tradeDTO,
pictureDTOList: combinedPictures,
profileImage: _post!.profileImage,
replyCnt: _post!.replyCnt,
regDate: _post!.regDate,
modDate: _post!.modDate,
liked: _post!.liked,
);

// 5) 서버로 수정 요청
await PostService.updatePost(updatedPost);

// 6) 최신 데이터 다시 가져오기
await _fetchPostDetail();

// 7) 수정 모드 종료
setState(() {
_isEditing = false;
_isLoading = false;
_uploadedNewPictures.clear();
_newAttachedImages.clear();
});
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('게시글 수정 실패: $e')),
);
setState(() {
_isLoading = false;
});
}
}

/// 게시글 삭제
Future<void> _deletePost() async {
if (_post == null) return;

final should = await showDialog<bool>(
context: context,
builder: (_) => AlertDialog(
title: const Text('삭제 확인'),
content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
actions: [
TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
TextButton(
onPressed: () => Navigator.of(context).pop(true),
child: const Text('삭제', style: TextStyle(color: Colors.red)),
),
],
),
);
if (should != true) return;

setState(() {
_isLoading = true;
_errorMessage = '';
});
try {
await PostService.deletePost(_post!.postId!);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('게시글이 삭제되었습니다.')),
);
Future.delayed(const Duration(seconds: 1), () {
Navigator.of(context).pop(true);
});
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('게시글 삭제 실패: ${e.toString()}')),
);
setState(() {
_isLoading = false;
});
}
}

/// 댓글 항목을 그리는 위젯
Widget _buildCommentItem(Comment comment) {
final currentUserId = Provider.of<AuthProvider>(context, listen: false).userId;
final isAuthor = currentUserId != null && comment.userId == currentUserId;

// edit 컨트롤러 초기화
if (!_editCommentControllers.containsKey(comment.replyId)) {
_editCommentControllers[comment.replyId] = TextEditingController(text: comment.content);
}
if (!_isEditingComment.containsKey(comment.replyId)) {
_isEditingComment[comment.replyId] = false;
}

return Container(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ── 상단: 작성자 닉네임, 작성일, (작성자면) 수정/삭제 ───────────────────
Row(
children: [
Text(
comment.userNickname,
style: const TextStyle(
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(width: 8),
Text(
// regDate를 로컬 문자열로 변환 (예: "2025-06-03T12:00:00" → "2025-06-03 12:00:00")
DateTime.tryParse(comment.regDate) != null
? DateTime.parse(comment.regDate).toLocal().toString().split('.')[0]
    : comment.regDate,
style: const TextStyle(fontSize: 12, color: Colors.grey),
),
const Spacer(),
if (isAuthor)
Row(
children: [
IconButton(
icon: const Icon(Icons.edit, size: 20, color: Colors.white70),
onPressed: () {
setState(() {
_isEditingComment[comment.replyId] = true;
});
},
),
IconButton(
icon: const Icon(Icons.delete, size: 20, color: Colors.white70),
onPressed: () => _deleteComment(comment.replyId),
),
],
),
],
),

const SizedBox(height: 4),

// ── 수정 모드 TextField / 일반 모드 댓글 본문 ─────────────────────
if (_isEditingComment[comment.replyId] == true)
Row(
children: [
Expanded(
child: TextField(
controller: _editCommentControllers[comment.replyId],
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(
hintText: '댓글을 수정하세요',
hintStyle: TextStyle(color: Colors.white54),
enabledBorder: UnderlineInputBorder(
borderSide: BorderSide(color: Colors.white54),
),
focusedBorder: UnderlineInputBorder(
borderSide: BorderSide(color: Colors.white),
),
),
),
),
IconButton(
icon: const Icon(Icons.check, color: Colors.green),
onPressed: () => _updateComment(comment.replyId),
),
IconButton(
icon: const Icon(Icons.close, color: Colors.red),
onPressed: () {
setState(() {
_isEditingComment[comment.replyId] = false;
});
},
),
],
)
else
Text(
comment.content, // 반드시 “content”를 출력
style: const TextStyle(color: Colors.white70, fontSize: 14),
),

const Divider(color: Colors.white24),
],
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.black,
appBar: AppBar(
title: const Text('게시글 상세'),
backgroundColor: Colors.black,
foregroundColor: Colors.white,
actions: [
if (!_isLoading && _post != null && !_isEditing)
IconButton(
icon: const Icon(Icons.edit),
onPressed: _startEditing,
),
],
),
body: _isLoading
? const Center(child: CircularProgressIndicator(color: Colors.orange))
    : _errorMessage.isNotEmpty
? Center(
child: Text(
_errorMessage,
style: const TextStyle(color: Colors.redAccent),
),
)
    : _isEditing
? _buildEditView()    // 게시글 수정 모드 화면 (아래에서 정의)
    : _buildDetailView(), // 게시글 & 댓글 상세 뷰 (아래에서 정의)
);
}

// ── 게시글 수정 모드 화면 ─────────────────────────────────────────
Widget _buildEditView() {
return SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ─── 제목 입력 ─────────────────────────────────────
TextField(
controller: _titleController,
style: const TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
decoration: const InputDecoration(
hintText: '제목을 입력하세요',
hintStyle: TextStyle(color: Colors.white54),
enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
),
),
const SizedBox(height: 16),

// ─── 태그 입력 ─────────────────────────────────────
TextField(
controller: _tagController,
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(
hintText: '태그를 입력하세요',
hintStyle: TextStyle(color: Colors.white54),
enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
),
),
const SizedBox(height: 16),

// ─── 새 이미지 첨부 버튼 ───────────────────────────
ElevatedButton.icon(
onPressed: _isPickingImage ? null : _pickNewImage,
icon: const Icon(Icons.add_photo_alternate),
label: const Text('이미지 추가'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white10,
foregroundColor: Colors.white,
disabledForegroundColor: Colors.white.withOpacity(0.5),
disabledBackgroundColor: Colors.white10.withOpacity(0.5),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
),
),
const SizedBox(height: 16),

// ─── 기존+새로 고른 이미지 표시 및 썸네일/삭제 기능 ─────
if (_existingPictures.isNotEmpty || _newAttachedImages.isNotEmpty) ...[
Wrap(
spacing: 8,
runSpacing: 8,
children: [
// 1) 서버에 있던 기존 이미지들
..._existingPictures.map((pic) {
final isSelected = pic.picId == _selectedThumbnailId;
String? path = pic.thumbnailImagePath ?? pic.resizedImagePath ?? pic.originImagePath;
Widget imageWidget;
if (path != null && path.isNotEmpty) {
imageWidget = Image.network(
"http://192.168.219.102:8080/ourlog/picture/display/$path",
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
color: Colors.grey[800],
child: const Icon(
Icons.broken_image,
color: Colors.white54,
size: 40,
),
),
);
} else {
imageWidget = Container(
color: Colors.grey[800],
child: const Icon(
Icons.broken_image,
color: Colors.white54,
size: 40,
),
);
}
return Stack(
alignment: Alignment.topRight,
children: [
// 썸네일 선택
GestureDetector(
onTap: () {
if (pic.picId != null) {
_selectThumbnail(pic.picId!);
}
},
child: Container(
width: 100,
height: 100,
decoration: BoxDecoration(
border: isSelected
? Border.all(color: Colors.blueAccent, width: 3)
    : null,
borderRadius: BorderRadius.circular(8),
),
clipBehavior: Clip.hardEdge,
child: imageWidget,
),
),
// 삭제 버튼 (X)
Positioned(
top: 4,
left: 4,
child: GestureDetector(
onTap: () => _removeExistingPicture(pic),
child: Container(
decoration: BoxDecoration(
color: Colors.black54,
borderRadius: BorderRadius.circular(12),
),
padding: const EdgeInsets.all(4),
child: const Icon(
Icons.close,
color: Colors.white,
size: 16,
),
),
),
),
// 썸네일 선택 표시
if (isSelected)
const Positioned(
top: 4,
right: 4,
child: Icon(
Icons.check_circle,
color: Colors.blueAccent,
),
),
],
);
}).toList(),

// 2) 로컬에서 새로 고른 이미지들
..._newAttachedImages.map((file) {
final fakeId = file.hashCode;
final isSelected = fakeId == _selectedThumbnailId;
return GestureDetector(
onTap: () => _selectThumbnail(fakeId),
child: Stack(
alignment: Alignment.topRight,
children: [
Container(
width: 100,
height: 100,
decoration: BoxDecoration(
border: isSelected
? Border.all(color: Colors.blueAccent, width: 3)
    : null,
borderRadius: BorderRadius.circular(8),
),
clipBehavior: Clip.hardEdge,
child: Image.file(
file,
fit: BoxFit.cover,
),
),
if (isSelected)
const Positioned(
top: 4,
right: 4,
child: Icon(Icons.check_circle, color: Colors.blueAccent),
),
],
),
);
}).toList(),
],
),
const SizedBox(height: 24),
],

// ─── 내용 입력 ─────────────────────────────────────
TextField(
controller: _contentController,
maxLines: null,
style: const TextStyle(color: Colors.white, fontSize: 14),
decoration: const InputDecoration(
hintText: '내용을 입력하세요',
hintStyle: TextStyle(color: Colors.white54),
enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
),
),
const SizedBox(height: 24),

// ─── 버튼 모음 (저장, 취소, 삭제) ─────────────────────
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
ElevatedButton(
onPressed: _saveEdit,
style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
child: const Text('저장'),
),
ElevatedButton(
onPressed: () {
setState(() {
_isEditing = false;
_newAttachedImages.clear();
_uploadedNewPictures.clear();
// _selectedThumbnailId는 그대로 둠
});
},
style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
child: const Text('취소'),
),
ElevatedButton(
onPressed: _deletePost,
style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
child: const Text('삭제'),
),
],
),
],
),
);
}

// ── 게시글 상세 화면 + 댓글 섹션 ───────────────────────────────────
Widget _buildDetailView() {
final post = _post;
if (post == null) {
return const Center(
child: Text(
'게시글을 찾을 수 없습니다.',
style: TextStyle(color: Colors.white70),
),
);
}

// ── 썸네일 결정 ─────────────────────────────────────────
String? thumbnailUrl;
final allPics = post.pictureDTOList ?? [];
if (post.thumbnailImagePath != null && post.thumbnailImagePath!.isNotEmpty) {
thumbnailUrl = "http://192.168.219.102:8080/ourlog/picture/display/${post.thumbnailImagePath}";
} else if (allPics.isNotEmpty) {
final first = allPics.first;
if (first.resizedImagePath != null && first.resizedImagePath!.isNotEmpty) {
thumbnailUrl = "http://192.168.219.102:8080/ourlog/picture/display/${first.resizedImagePath}";
} else if (first.thumbnailImagePath != null && first.thumbnailImagePath!.isNotEmpty) {
thumbnailUrl = "http://192.168.219.102:8080/ourlog/picture/display/${first.thumbnailImagePath}";
} else if (first.originImagePath != null && first.originImagePath!.isNotEmpty) {
thumbnailUrl = "http://192.168.219.102:8080/ourlog/picture/display/${first.originImagePath}";
} else {
thumbnailUrl = null;
}
} else {
thumbnailUrl = null;
}

// ── 이미지 섹션량 분기 ─────────────────────────────────────────
final hasMultiple = allPics.length > 1;
Widget imageSection;
if (allPics.isEmpty) {
imageSection = const SizedBox.shrink();
} else if (!hasMultiple && thumbnailUrl != null) {
imageSection = ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Image.network(
thumbnailUrl,
width: double.infinity,
fit: BoxFit.contain,
errorBuilder: (_, __, ___) => Container(
width: double.infinity,
color: Colors.grey[800],
child: const Icon(
Icons.broken_image,
color: Colors.white54,
size: 50,
),
),
),
);
} else if (hasMultiple) {
imageSection = SizedBox(
height: 120,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: allPics.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (_, idx) {
final pic = allPics[idx];
String? imageUrl;
if (pic.resizedImagePath != null && pic.resizedImagePath!.isNotEmpty) {
imageUrl = "http://192.168.219.102:8080/ourlog/picture/display/${pic.resizedImagePath}";
} else if (pic.thumbnailImagePath != null && pic.thumbnailImagePath!.isNotEmpty) {
imageUrl = "http://192.168.219.102:8080/ourlog/picture/display/${pic.thumbnailImagePath}";
} else if (pic.originImagePath != null && pic.originImagePath!.isNotEmpty) {
imageUrl = "http://192.168.219.102:8080/ourlog/picture/display/${pic.originImagePath}";
}
if (imageUrl == null) {
return Container(
width: 120,
height: 120,
color: Colors.grey[800],
child: const Icon(
Icons.broken_image,
color: Colors.white54,
size: 40,
),
);
}
return ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Image.network(
imageUrl,
width: 120,
height: 120,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) => Container(
width: 120,
height: 120,
color: Colors.grey[800],
child: const Icon(
Icons.broken_image,
color: Colors.white54,
size: 40,
),
),
),
);
},
),
);
} else {
imageSection = const SizedBox.shrink();
}

return SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ■ 제목
Text(
post.title ?? '제목 없음',
style: const TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 16),

// ■ 이미지 영역
imageSection,
if (allPics.isNotEmpty) const SizedBox(height: 16),

// ■ 본문 내용
Text(
post.content ?? '내용 없음',
style: const TextStyle(color: Colors.white70, fontSize: 14),
),
const SizedBox(height: 24),

// ■ 댓글(답글) 섹션 ───────────────────────────────────────────────
const Text(
'댓글',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
const SizedBox(height: 8),

// 댓글 목록 로딩 중 표시
_commentsLoading
? const Center(child: CircularProgressIndicator(color: Colors.orange))
    : Column(
children: _comments.map((c) => _buildCommentItem(c)).toList(),
),

// ── 새 댓글 입력창 ─────────────────────────────────────
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: TextField(
controller: _newCommentController,
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(
hintText: '댓글 입력...',
hintStyle: TextStyle(color: Colors.white54),
enabledBorder: OutlineInputBorder(
borderSide: BorderSide(color: Colors.white54)),
focusedBorder: OutlineInputBorder(
borderSide: BorderSide(color: Colors.white)),
),
),
),
const SizedBox(width: 8),
IconButton(
icon: const Icon(Icons.send, color: Colors.white),
onPressed: _addComment,
),
],
),
],
),
);
}
}
