import '../../models/post.dart';
import '../../services/post_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 게시글 상세 조회용 Provider
final postDetailProvider = StateNotifierProvider.family<PostDetailNotifier, AsyncValue<Post?>, int>(
  (ref, postId) => PostDetailNotifier(postId),
);

class PostDetailNotifier extends StateNotifier<AsyncValue<Post?>> {
  final int postId;

  PostDetailNotifier(this.postId) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    final post = await PostService.fetchPost(postId);
    state = AsyncData(post);
  }

  Future<void> refresh() async => load();
}
