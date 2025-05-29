import 'package:flutter/material.dart';
import '../../services/post/post_service.dart'; // PostService import 경로 확인
import '../../models/post/post.dart'; // Post model import 경로 확인

class CommunityPostDetailScreen extends StatefulWidget {
  final int postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }

  Future<void> _fetchPostDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Post fetchedPost = await PostService.getPostById(widget.postId);
      print('Fetched postId: ${widget.postId}'); // 넘겨받은 postId 확인
      print('Fetched Post Raw Data: ${fetchedPost.toJson()}'); // 백엔드에서 받은 Raw 데이터 확인
      print('Post Title: ${fetchedPost.title}');
      print('Post Nickname: ${fetchedPost.nickname}');
      print('Post Content: ${fetchedPost.content}');
      print('Post RegDate: ${fetchedPost.regDate}');
      setState(() {
        _post = fetchedPost;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '게시글 로딩 실패: ${e.toString()}';
        print('Error fetching post detail: $e'); // 디버깅을 위해 에러 출력
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경색 검은색
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.black, // 앱바 배경 검은색
        foregroundColor: Colors.white, // 앱바 아이콘 및 텍스트 흰색
        // elevation: 0, // 앱바 그림자 제거 - 등록 화면과 일관성을 위해 제거
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange)) // 로딩 인디케이터
          : _errorMessage.isNotEmpty // 에러 메시지가 있을 경우
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
          : _post == null // 게시글 데이터가 없을 경우
          ? const Center(child: Text('게시글을 찾을 수 없습니다.', style: TextStyle(color: Colors.white70)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 제목
            Text(
              _post!.title ?? '제목 없음',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // 상세 페이지 제목은 등록 페이지 섹션 제목보다 크게 유지
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // 제목 아래 간격

            // 2. 작성자, 조회수, 등록일, 수정일 정보 (한 줄에 표시)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝 정렬
              crossAxisAlignment: CrossAxisAlignment.start, // 세로 정렬 시작점 (텍스트 베이스라인 맞추기)
              children: [
                // 작성자 및 조회수 정보 (왼쪽)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '작성자: ${_post!.nickname ?? '알 수 없음'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4), // 작성자와 조회수 사이 간격
                    Text(
                      '조회수: ${_post!.views ?? 0}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),

                // 등록일 및 수정일 정보 (오른쪽)
                Column(
                   crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬
                   children: [
                      Text(
                       '등록일: ${_post!.regDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}', // 날짜만 추출
                       style: const TextStyle(color: Colors.white54, fontSize: 14),
                     ),
                     const SizedBox(height: 4), // 등록일과 수정일 사이 간격
                     Text(
                       '수정일: ${_post!.modDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}', // 날짜만 추출
                       style: const TextStyle(color: Colors.white54, fontSize: 14),
                     ),
                   ],
                ),
              ],
            ),
            const SizedBox(height: 16), // 정보 줄과 구분선 사이 간격
            Container(
              height: 2, // 구분선 높이를 등록 화면과 동일하게 변경
              color: Colors.orange, // 구분선 색상을 등록 화면과 동일하게 변경
            ),
            const SizedBox(height: 16),

            // 3. 이미지 목록 (있는 경우)
            if (_post!.pictureDTOList != null && _post!.pictureDTOList!.isNotEmpty)
              Container(
                height: 200, // 이미지 갤러리의 높이
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, // 가로 스크롤
                  itemCount: _post!.pictureDTOList!.length,
                  itemBuilder: (context, index) {
                    final picture = _post!.pictureDTOList![index];
                    // 이미지 URL 구성 (resiezedPath 우선, 없으면 originPath, 없으면 플레이스홀더)
                    // Post 모델의 getImageUrl 메서드를 사용하여 URL 가져오기
                    final imageUrl = _post!.getImageUrl(); // 변경: Post 모델의 getImageUrl 사용
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect( // 이미지를 둥글게 자르기 위해 추가
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          imageUrl,
                          width: 200, // 가로 크기
                          height: 200, // 세로 크기 (일관성 유지)
                          fit: BoxFit.cover, // 이미지가 컨테이너를 채우도록 설정
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey, // 에러 시 회색 배경
                            child: const Icon(Icons.broken_image, color: Colors.white, size: 50), // 에러 아이콘
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_post!.pictureDTOList != null && _post!.pictureDTOList!.isNotEmpty)
              const SizedBox(height: 16), // 이미지가 있을 경우에만 공간 추가

            // 4. 내용
            Text(
              _post!.content ?? '내용 없음',
              style: const TextStyle(color: Colors.white, fontSize: 14), // 등록 화면 내용 텍스트 크기와 유사하게 조정
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}